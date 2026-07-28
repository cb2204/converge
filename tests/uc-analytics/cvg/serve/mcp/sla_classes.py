"""Serve — partner SLA classes (R-9).

Three budgets, in seconds, that every MCP tool call is classified into.
The numbers come straight from the tech-spec's small/medium/hard bands
(<=5m/<=30m/<=60m) — nothing here is invented locally.
"""

from __future__ import annotations

SMALL_SECONDS = 300    # <=5m  — single-metric point reads (e.g. total_revenue)
MEDIUM_SECONDS = 1800  # <=30m — grouped/aggregated reads (e.g. revenue_by_product)
HARD_SECONDS = 3600    # <=60m — multi-table or growth-drill (3x) reads

SLA_CLASSES = {
    "small": SMALL_SECONDS,
    "medium": MEDIUM_SECONDS,
    "hard": HARD_SECONDS,
}


def classify(tool_name: str) -> str:
    """Which SLA class a given MCP tool belongs to. Unknown tools default
    to 'hard' — the widest budget — never a class that overpromises."""
    return TOOL_SLA.get(tool_name, "hard")


# Per-tool SLA assignment, kept next to server.py's TOOLS so the two stay
# in lockstep — a tool without an entry here is treated as 'hard'.
TOOL_SLA = {
    "total_revenue": "small",
    "revenue_by_product": "medium",
    "gold_freshness": "small",
}


def budget_seconds(tool_name: str) -> int:
    return SLA_CLASSES[classify(tool_name)]
