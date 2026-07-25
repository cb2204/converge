"""Unit checks for the dependency-free pgoutput decoder."""

from __future__ import annotations

import importlib.util
import struct
import sys
from datetime import UTC, datetime
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "pipelines" / "orders.py"
SPEC = importlib.util.spec_from_file_location("orders_pipeline", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
orders = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = orders
SPEC.loader.exec_module(orders)


def _cstring(value: str) -> bytes:
    return value.encode() + b"\x00"


def _tuple(values: list[str]) -> bytes:
    encoded = struct.pack("!H", len(values))
    for value in values:
        raw = value.encode()
        encoded += b"t" + struct.pack("!I", len(raw)) + raw
    return encoded


def test_decodes_committed_order_insert() -> None:
    relation_id = 41
    columns = ("order_id", "status")
    relation = b"R" + struct.pack("!I", relation_id) + _cstring("public") + _cstring("orders") + b"d"
    relation += struct.pack("!H", len(columns))
    for column in columns:
        relation += b"\x00" + _cstring(column) + struct.pack("!II", 25, 0xFFFFFFFF)

    inserted = b"I" + struct.pack("!I", relation_id) + b"N" + _tuple(["9001", "placed"])
    committed_at = datetime(2026, 7, 25, 12, 30, tzinfo=UTC)
    micros = int((committed_at - orders.PG_EPOCH).total_seconds() * 1_000_000)
    begin = b"B" + struct.pack("!QqI", 0x1600000180, micros, 77)
    commit = b"C" + struct.pack("!BQQq", 0, 0x1600000180, 0x16000001A0, micros)

    changes = orders.parse_pgoutput(
        [
            ("16/100", 77, begin),
            ("16/110", 77, relation),
            ("16/120", 77, inserted),
            ("16/180", 77, commit),
        ]
    )

    assert changes == [
        orders.CommittedChange(
            order_id=9001,
            lsn="16/120",
            operation="insert",
            source_committed_at=committed_at,
        )
    ]


def test_discards_uncommitted_order_change() -> None:
    relation_id = 9
    relation = (
        b"R"
        + struct.pack("!I", relation_id)
        + _cstring("public")
        + _cstring("orders")
        + b"d"
        + struct.pack("!H", 1)
        + b"\x00"
        + _cstring("order_id")
        + struct.pack("!II", 20, 0xFFFFFFFF)
    )
    inserted = b"I" + struct.pack("!I", relation_id) + b"N" + _tuple(["7"])

    changes = orders.parse_pgoutput(
        [
            ("0/10", 2, b"B" + struct.pack("!QqI", 20, 0, 2)),
            ("0/11", 2, relation),
            ("0/12", 2, inserted),
        ]
    )

    assert changes == []
