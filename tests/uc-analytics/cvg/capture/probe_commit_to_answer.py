"""Commit one source order and prove its WAL change reaches raw.orders."""

from __future__ import annotations

import json
import sys
import time
import uuid
from datetime import UTC, datetime
from pathlib import Path

from pipelines.orders import CaptureError, OrdersPipeline, Psql


FRESHNESS_BUDGET_SECONDS = 300.0


def provision_capture_principal(psql: Psql) -> None:
    """Apply the idempotent capture-principal definition."""
    principal_sql = Path(__file__).with_name("principal.sql").read_text(encoding="utf-8")
    psql.run(principal_sql)


def insert_probe_order(psql: Psql) -> int:
    """Commit one valid order to the operational source and return its id."""
    customer_column = psql.run(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'orders'
          AND column_name IN ('customer_id', 'user_id')
        ORDER BY CASE column_name WHEN 'customer_id' THEN 0 ELSE 1 END
        LIMIT 1;
        """
    )
    if customer_column not in {"customer_id", "user_id"}:
        raise CaptureError("public.orders has no supported customer-reference column")

    probe_status = f"cvg-probe-{uuid.uuid4().hex[:12]}"
    output = psql.run(
        f"""
        INSERT INTO public.orders (
            {customer_column},
            product_id,
            quantity,
            unit_price,
            total_amount,
            status,
            ordered_at
        )
        SELECT
            (SELECT customer_id FROM public.customers ORDER BY customer_id LIMIT 1),
            product_id,
            1,
            unit_price,
            unit_price,
            '{probe_status}',
            clock_timestamp()
        FROM public.products
        ORDER BY product_id
        LIMIT 1
        RETURNING order_id;
        """
    )
    try:
        return int(output)
    except ValueError as exc:
        raise CaptureError("the source fixture needs at least one customer and product") from exc


def served_answer(psql: Psql, order_id: int) -> tuple[str, datetime, datetime]:
    """Read the landed answer and its two freshness timestamps."""
    output = psql.run(
        f"""
        SELECT _op, _captured_at::text, _source_committed_at::text
        FROM raw.orders
        WHERE order_id = {order_id}
        ORDER BY _captured_at DESC
        LIMIT 1;
        """
    )
    fields = output.split("\t")
    if len(fields) != 3:
        raise CaptureError(f"order {order_id} is absent from the served answer")
    operation, captured_text, committed_text = fields
    return operation, datetime.fromisoformat(captured_text), datetime.fromisoformat(committed_text)


def main() -> int:
    """Run the complete source-commit to served-answer probe."""
    started = time.monotonic()
    psql = Psql()
    psql.ensure_logical_wal()
    provision_capture_principal(psql)

    pipeline = OrdersPipeline(psql)
    pipeline.prepare()
    order_id = insert_probe_order(psql)
    decoded = pipeline.capture_until(order_id)
    operation, captured_at, committed_at = served_answer(psql, order_id)

    if operation != "insert" or decoded.operation != "insert":
        raise CaptureError(f"expected insert change for order {order_id}, got {operation!r}")
    freshness_seconds = (captured_at - committed_at).total_seconds()
    if freshness_seconds < 0 or freshness_seconds > FRESHNESS_BUDGET_SECONDS:
        raise CaptureError(
            f"order {order_id} freshness {freshness_seconds:.3f}s exceeded "
            f"{FRESHNESS_BUDGET_SECONDS:.0f}s"
        )

    print(
        json.dumps(
            {
                "order_id": order_id,
                "lsn": decoded.lsn,
                "operation": operation,
                "source_committed_at": committed_at.astimezone(UTC).isoformat(),
                "captured_at": captured_at.astimezone(UTC).isoformat(),
                "freshness_seconds": round(freshness_seconds, 6),
                "probe_seconds": round(time.monotonic() - started, 6),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (CaptureError, OSError) as exc:
        print(f"capture probe failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
