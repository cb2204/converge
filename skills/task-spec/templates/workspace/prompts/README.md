# `_prompts/` — the canonical pass prompts

One blueprint prompt per pass. These are the **steering contracts**: hand the
right one to your agent at the start of each pass — paste it into the chat, or
just say *"follow `cvg/brain/_prompts/pass-N-….md`"* — and the pass runs the
way the method intends, in any harness.

Which passes you run is not a choice you make here: **`cvg lane` decides**
(FAST = 5→7→8 · NORMAL = 1→2→5→7→8 · FULL = 0→8). Between tasks, `cvg ready`
answers "what now"; `cvg setup` prints the exact next step when anything is
missing.

## Rules that apply to every pass

- **The referee decides done.** A pass is complete when its `cvg` gate prints
  its PASS/OK token — never when the work "looks finished".
- **Never open held-back material.** If the project carries an answer key,
  oracle, or holdout criteria (files the human designates as judge-only), do
  not read them. They exist to catch you.
- **Never edit a sealed eval.** After `cvg tasks gate --stamp`, changing an
  eval breaks the HMAC seal and every downstream gate refuses.
- **Fill the right folder.** Every artifact has a home; a pass that leaves its
  folder empty is a pass that didn't happen:

| Folder | Filled by | With |
|---|---|---|
| `cvg/brain/transcripts/` | every pass | interview notes, dispatch summaries |
| `cvg/brain/decisions/` | every pass | judgment calls that shaped the work |
| `cvg/docs/` | passes 0–2 | BRD, tech spec, `adrs/` |
| `cvg/sketch/` | passes 3–4 | swimlanes, objection log |
| `cvg/tasks/` | pass 5 | signed Task-Specs (`done/`, `parked/` lifecycle) |
| `cvg/execution/` | pass 7 | execution profiles + adapter manifests |
| `cvg/loop/` | pass 8 | per-task run state (scratch, git-excluded) |
| `cvg/receipts/` | pass 8 | settlement receipts — the evidence trail |
