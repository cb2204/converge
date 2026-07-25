"""Logical-WAL capture for the orders steel thread.

The module deliberately uses PostgreSQL's built-in ``pgoutput`` decoder rather
than a row timestamp or polling query.  It has no third-party Python
dependencies: database commands run through the ``psql`` already present in
the fixture's Postgres container.
"""

from __future__ import annotations

import argparse
import re
import struct
import subprocess
import time
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Final


PUBLICATION: Final = "cvg_orders_publication"
SLOT: Final = "cvg_orders_capture"
CAPTURE_ROLE: Final = "capture_reader"
CAPTURE_PASSWORD: Final = "capture_reader"
PG_EPOCH: Final = datetime(2000, 1, 1, tzinfo=UTC)
LSN_PATTERN: Final = re.compile(r"^[0-9A-F]+/[0-9A-F]+$")


class CaptureError(RuntimeError):
    """Raised when the capture pipeline cannot preserve its contract."""


@dataclass(frozen=True)
class Relation:
    """The relation metadata emitted by pgoutput."""

    namespace: str
    name: str
    columns: tuple[str, ...]


@dataclass(frozen=True)
class PendingChange:
    """A decoded change awaiting its transaction's commit record."""

    order_id: int
    operation: str
    lsn: str


@dataclass(frozen=True)
class CommittedChange:
    """A committed orders change in the raw landing shape."""

    order_id: int
    lsn: str
    operation: str
    source_committed_at: datetime


class Psql:
    """Run deterministic SQL commands inside the local Postgres container."""

    def __init__(self, container: str = "uc-analytics-postgres", database: str = "ecommerce") -> None:
        self.container = container
        self.database = database

    def run(self, sql: str, *, user: str = "postgres", password: str | None = None) -> str:
        """Execute SQL with tuples-only, unaligned output and fail on SQL errors."""
        command = ["docker", "exec", "-i"]
        if password is not None:
            command.extend(["-e", f"PGPASSWORD={password}"])
        command.extend([self.container, "psql"])
        if password is not None:
            command.extend(["-h", "127.0.0.1"])
        command.extend(
            [
                "-X",
                "-q",
                "-v",
                "ON_ERROR_STOP=1",
                "-A",
                "-t",
                "-F",
                "\t",
                "-U",
                user,
                "-d",
                self.database,
            ]
        )
        completed = subprocess.run(
            command,
            input=sql,
            text=True,
            capture_output=True,
            check=False,
        )
        if completed.returncode != 0:
            detail = completed.stderr.strip() or completed.stdout.strip()
            raise CaptureError(f"psql failed for role {user}: {detail}")
        return completed.stdout.strip()

    def ensure_logical_wal(self, timeout_seconds: float = 30.0) -> None:
        """Enable logical decoding once, restarting the disposable fixture if needed."""
        if self.run("SHOW wal_level;") == "logical":
            return

        self.run("ALTER SYSTEM SET wal_level = 'logical';")
        restarted = subprocess.run(
            ["docker", "restart", self.container],
            text=True,
            capture_output=True,
            check=False,
        )
        if restarted.returncode != 0:
            raise CaptureError(f"could not restart {self.container}: {restarted.stderr.strip()}")

        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            ready = subprocess.run(
                [
                    "docker",
                    "exec",
                    self.container,
                    "pg_isready",
                    "-U",
                    "postgres",
                    "-d",
                    self.database,
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            if ready.returncode == 0:
                if self.run("SHOW wal_level;") != "logical":
                    raise CaptureError("Postgres restarted without wal_level=logical")
                return
            time.sleep(0.25)
        raise CaptureError(f"{self.container} did not become ready within {timeout_seconds:g}s")


def _read_cstring(payload: bytes, offset: int) -> tuple[str, int]:
    end = payload.find(b"\x00", offset)
    if end < 0:
        raise CaptureError("unterminated pgoutput string")
    return payload[offset:end].decode("utf-8"), end + 1


def _read_relation(payload: bytes) -> tuple[int, Relation]:
    if len(payload) < 8:
        raise CaptureError("truncated pgoutput relation message")
    relation_id = struct.unpack_from("!I", payload, 1)[0]
    namespace, offset = _read_cstring(payload, 5)
    name, offset = _read_cstring(payload, offset)
    offset += 1  # replica identity
    if offset + 2 > len(payload):
        raise CaptureError("truncated pgoutput relation column count")
    column_count = struct.unpack_from("!H", payload, offset)[0]
    offset += 2
    columns: list[str] = []
    for _ in range(column_count):
        offset += 1  # flags
        column, offset = _read_cstring(payload, offset)
        if offset + 8 > len(payload):
            raise CaptureError("truncated pgoutput relation column")
        offset += 8  # data type oid and type modifier
        columns.append(column)
    return relation_id, Relation(namespace=namespace, name=name, columns=tuple(columns))


def _read_tuple(payload: bytes, offset: int) -> tuple[list[str | bytes | None], int]:
    if offset + 2 > len(payload):
        raise CaptureError("truncated pgoutput tuple")
    column_count = struct.unpack_from("!H", payload, offset)[0]
    offset += 2
    values: list[str | bytes | None] = []
    for _ in range(column_count):
        if offset >= len(payload):
            raise CaptureError("truncated pgoutput tuple value")
        kind = chr(payload[offset])
        offset += 1
        if kind == "n":
            values.append(None)
        elif kind == "u":
            values.append("unchanged")
        elif kind in {"t", "b"}:
            if offset + 4 > len(payload):
                raise CaptureError("truncated pgoutput tuple value length")
            length = struct.unpack_from("!I", payload, offset)[0]
            offset += 4
            if offset + length > len(payload):
                raise CaptureError("truncated pgoutput tuple value body")
            raw = payload[offset : offset + length]
            offset += length
            values.append(raw.decode("utf-8") if kind == "t" else raw)
        else:
            raise CaptureError(f"unknown pgoutput tuple kind: {kind!r}")
    return values, offset


def _order_id(relation: Relation, values: list[str | bytes | None]) -> int:
    try:
        index = relation.columns.index("order_id")
        value = values[index]
    except (ValueError, IndexError) as exc:
        raise CaptureError("orders change did not carry order_id") from exc
    if not isinstance(value, str) or value == "unchanged":
        raise CaptureError("orders change carried an unusable order_id")
    try:
        return int(value)
    except ValueError as exc:
        raise CaptureError(f"orders change carried invalid order_id {value!r}") from exc


def _decode_change(
    payload: bytes,
    relation: Relation,
    wal_lsn: str,
) -> PendingChange | None:
    message_type = chr(payload[0])
    offset = 5
    values: list[str | bytes | None]

    if message_type == "I":
        if chr(payload[offset]) != "N":
            raise CaptureError("insert message did not contain a new tuple")
        values, _ = _read_tuple(payload, offset + 1)
        operation = "insert"
    elif message_type == "U":
        marker = chr(payload[offset])
        if marker in {"K", "O"}:
            _, offset = _read_tuple(payload, offset + 1)
            marker = chr(payload[offset])
        if marker != "N":
            raise CaptureError("update message did not contain a new tuple")
        values, _ = _read_tuple(payload, offset + 1)
        operation = "update"
    elif message_type == "D":
        marker = chr(payload[offset])
        if marker not in {"K", "O"}:
            raise CaptureError("delete message did not contain an old key")
        values, _ = _read_tuple(payload, offset + 1)
        operation = "delete"
    else:
        return None

    if relation.namespace != "public" or relation.name != "orders":
        return None
    if not LSN_PATTERN.fullmatch(wal_lsn):
        raise CaptureError(f"invalid WAL LSN returned by Postgres: {wal_lsn!r}")
    return PendingChange(order_id=_order_id(relation, values), operation=operation, lsn=wal_lsn)


def parse_pgoutput(records: list[tuple[str, int, bytes]]) -> list[CommittedChange]:
    """Decode pgoutput records and return only committed orders changes."""
    relations: dict[int, Relation] = {}
    pending: list[PendingChange] = []
    committed: list[CommittedChange] = []

    for wal_lsn, _xid, payload in records:
        if not payload:
            raise CaptureError("empty pgoutput message")
        message_type = chr(payload[0])
        if message_type == "B":
            pending = []
        elif message_type == "R":
            relation_id, relation = _read_relation(payload)
            relations[relation_id] = relation
        elif message_type in {"I", "U", "D"}:
            if len(payload) < 6:
                raise CaptureError("truncated pgoutput change message")
            relation_id = struct.unpack_from("!I", payload, 1)[0]
            relation = relations.get(relation_id)
            if relation is None:
                raise CaptureError(f"pgoutput change references unknown relation {relation_id}")
            change = _decode_change(payload, relation, wal_lsn)
            if change is not None:
                pending.append(change)
        elif message_type == "C":
            if len(payload) < 26:
                raise CaptureError("truncated pgoutput commit message")
            committed_micros = struct.unpack_from("!q", payload, 18)[0]
            committed_at = PG_EPOCH + timedelta(microseconds=committed_micros)
            committed.extend(
                CommittedChange(
                    order_id=change.order_id,
                    lsn=change.lsn,
                    operation=change.operation,
                    source_committed_at=committed_at,
                )
                for change in pending
            )
            pending = []
    return committed


def _sql_string(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


class OrdersPipeline:
    """Own the publication, logical slot, decoding, and raw landing."""

    def __init__(self, psql: Psql | None = None) -> None:
        self.psql = psql or Psql()

    def prepare(self) -> None:
        """Create the raw seam, orders publication, and logical slot."""
        self.psql.run(
            """
            CREATE SCHEMA IF NOT EXISTS raw;
            CREATE TABLE IF NOT EXISTS raw.orders (
                order_id BIGINT NOT NULL,
                _lsn PG_LSN NOT NULL,
                _op TEXT NOT NULL CHECK (_op IN ('insert', 'update', 'delete')),
                _captured_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
                _source_committed_at TIMESTAMPTZ NOT NULL
            );
            """
        )

        published = self.psql.run(
            f"""
            SELECT count(*)
            FROM pg_catalog.pg_publication_tables
            WHERE pubname = {_sql_string(PUBLICATION)}
              AND schemaname = 'public'
              AND tablename = 'orders';
            """
        )
        if published == "0":
            exists = self.psql.run(
                f"SELECT count(*) FROM pg_catalog.pg_publication WHERE pubname = {_sql_string(PUBLICATION)};"
            )
            if exists == "0":
                self.psql.run(f"CREATE PUBLICATION {PUBLICATION} FOR TABLE public.orders;")
            else:
                self.psql.run(f"ALTER PUBLICATION {PUBLICATION} ADD TABLE public.orders;")

        slot_plugin = self.psql.run(
            f"SELECT plugin FROM pg_catalog.pg_replication_slots WHERE slot_name = {_sql_string(SLOT)};"
        )
        if slot_plugin and slot_plugin != "pgoutput":
            raise CaptureError(f"replication slot {SLOT} uses unexpected plugin {slot_plugin!r}")
        if not slot_plugin:
            self.psql.run(
                f"SELECT slot_name FROM pg_catalog.pg_create_logical_replication_slot("
                f"{_sql_string(SLOT)}, 'pgoutput');",
                user=CAPTURE_ROLE,
                password=CAPTURE_PASSWORD,
            )

    def _read_slot(self, function: str) -> list[tuple[str, int, bytes]]:
        sql = (
            "SELECT lsn::text, xid, encode(data, 'hex') "
            f"FROM pg_catalog.{function}("
            f"{_sql_string(SLOT)}, NULL, NULL, "
            f"'proto_version', '1', 'publication_names', {_sql_string(PUBLICATION)});"
        )
        output = self.psql.run(sql, user=CAPTURE_ROLE, password=CAPTURE_PASSWORD)
        records: list[tuple[str, int, bytes]] = []
        for line in output.splitlines():
            if not line:
                continue
            fields = line.split("\t", 2)
            if len(fields) != 3:
                raise CaptureError(f"unexpected logical-slot output: {line!r}")
            lsn, xid, encoded = fields
            try:
                records.append((lsn, int(xid), bytes.fromhex(encoded)))
            except ValueError as exc:
                raise CaptureError(f"invalid logical-slot output: {line!r}") from exc
        return records

    def peek(self) -> tuple[list[tuple[str, int, bytes]], list[CommittedChange]]:
        """Peek available WAL without advancing the durable checkpoint."""
        records = self._read_slot("pg_logical_slot_peek_binary_changes")
        return records, parse_pgoutput(records)

    def land(self, changes: list[CommittedChange]) -> None:
        """Append committed change records to the frozen raw.orders seam."""
        if not changes:
            return
        values = ",\n".join(
            "("
            f"{change.order_id}, "
            f"{_sql_string(change.lsn)}::pg_lsn, "
            f"{_sql_string(change.operation)}, "
            "clock_timestamp(), "
            f"{_sql_string(change.source_committed_at.isoformat())}::timestamptz"
            ")"
            for change in changes
        )
        self.psql.run(
            "INSERT INTO raw.orders "
            "(order_id, _lsn, _op, _captured_at, _source_committed_at) "
            f"VALUES {values};"
        )

    def advance(self) -> None:
        """Consume the WAL batch only after its raw records have landed."""
        self._read_slot("pg_logical_slot_get_binary_changes")

    def capture_until(self, order_id: int, timeout_seconds: float = 30.0) -> CommittedChange:
        """Land WAL batches until the requested order is queryable."""
        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            records, changes = self.peek()
            if records:
                self.land(changes)
                self.advance()
                for change in changes:
                    if change.order_id == order_id:
                        return change
            time.sleep(0.1)
        raise CaptureError(f"order {order_id} did not reach raw.orders within {timeout_seconds:g}s")


def main(argv: list[str] | None = None) -> int:
    """Capture until an expected order id is observed."""
    parser = argparse.ArgumentParser()
    parser.add_argument("order_id", type=int)
    parser.add_argument("--timeout-seconds", type=float, default=30.0)
    args = parser.parse_args(argv)

    pipeline = OrdersPipeline()
    pipeline.prepare()
    change = pipeline.capture_until(args.order_id, args.timeout_seconds)
    print(
        f"order_id={change.order_id} lsn={change.lsn} "
        f"op={change.operation} committed_at={change.source_committed_at.isoformat()}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
