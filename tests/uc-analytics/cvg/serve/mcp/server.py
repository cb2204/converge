"""Serve — MCP partner/agent access over the shared core (leg-03).

Same seam as leg-01/leg-02: reads only the published `gold.*` contract via
`cvg/serve/core/reader.py` (below-seam isolation enforced by the
`serve_reader` grants, not by discipline here). Every tool call is
classified into one of three SLA budgets (`sla_classes.py`, R-9) and every
answer carries its `as_of` freshness (`cvg/serve/api/answers.py`, R-4) — a
partner reading through MCP gets the same honesty guarantees the FastAPI
surface gives a first-party caller, over the same core, stateless over
`gold.*` per the seam contract.

Stdlib-only, no MCP SDK dependency — this environment denies network, so
`TOOLS` is a plain, importable tool surface (name/description/sla/handler)
rather than a running server process. A real MCP transport (stdio/HTTP)
can wrap `TOOLS` directly without touching the seam logic below.
"""

from __future__ import annotations

import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE.parent / "core"))
sys.path.insert(0, str(_HERE.parent / "api"))
sys.path.insert(0, str(_HERE))

import reader  # noqa: E402
import answers  # noqa: E402
import sla_classes  # noqa: E402


def _tool_total_revenue() -> dict:
    return answers.total_revenue_answer()


def _tool_revenue_by_product() -> dict:
    reader.ensure_serve_role()
    rows = [r for r in reader.REVENUE_BY_PRODUCT.select().splitlines() if r]
    return {
        "metric": "revenue_by_product",
        "rows": rows,
        "as_of": answers.gold_as_of(),
    }


def _tool_gold_freshness() -> dict:
    return {"metric": "gold_as_of", "as_of": answers.gold_as_of()}


def _make_tool(name: str, description: str, handler) -> dict:
    return {
        "name": name,
        "description": description,
        "sla_class": sla_classes.classify(name),
        "budget_seconds": sla_classes.budget_seconds(name),
        "handler": handler,
    }


TOOLS = [
    _make_tool(
        "total_revenue",
        "Total captured revenue from gold.revenue, with as-of freshness.",
        _tool_total_revenue,
    ),
    _make_tool(
        "revenue_by_product",
        "Captured revenue grouped by product from gold.revenue_by_product.",
        _tool_revenue_by_product,
    ),
    _make_tool(
        "gold_freshness",
        "The current gold_as_of watermark this serving surface agrees with.",
        _tool_gold_freshness,
    ),
]

TOOLS_BY_NAME = {t["name"]: t for t in TOOLS}


def call_tool(name: str) -> dict:
    """Partner entry point: run one MCP tool by name and return its answer.
    Unknown tool names are refused, never resolved by falling through to a
    deeper read — same contract discipline as GoldReader."""
    if name not in TOOLS_BY_NAME:
        raise PermissionError(f"'{name}' is not an exposed MCP tool — refused")
    return TOOLS_BY_NAME[name]["handler"]()


def main() -> int:
    for tool in TOOLS:
        print(f"{tool['name']} [{tool['sla_class']} <= {tool['budget_seconds']}s] {tool['description']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
