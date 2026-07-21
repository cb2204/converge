# Engine adapter — how `cvg review` dispatches a headless adversary

The CLI is a **referee, never a player**: it holds no model credentials and never
calls an LLM API. It shells out to the engine's own headless CLI (which
authenticates itself), captures a schema-validated artifact, and gates it. This is
the reusable dispatch layer (Milestone 3.1) — Pass 4 is the first pass that needs
it; Pass 5B/8 reuse it.

## Interface — `adapters/engines/<engine>.sh`

One driver per engine behind a stable contract.

- **Inputs:** `$1` framed prompt file (the attack-playbook) · `$2` workdir (a
  read-only checkout / throwaway worktree of `sketch/`) · env `CVG_ADVERSARY_MODEL`,
  `CVG_TIMEOUT_SECS`, `CVG_OUT` (artifact path).
- **Behavior:** map to the real invocation (below), **always read-only**, request
  **schema-validated JSON**, **wrap in `timeout`**, write raw → `$CVG_OUT.raw` and
  the parsed objection-log → `$CVG_OUT`.
- **Never trust the engine exit code alone** (Codex `exec` exits 0 even on failure).
  Success = timeout didn't fire **AND** the artifact parses against
  `objection-log.schema.json` **AND** `verdict ∈ {PASS,REVISE}`. Else emit an
  `ERROR` verdict — **fail-closed, never a pass**.
- **Normalized adapter exit codes:** `0` valid artifact · `20` engine
  unavailable → SKIP · `21` timed out · `22` produced-but-malformed → ERROR ·
  `75` retryable (429/5xx) — propagate Kimi's 75, map Codex/Claude transient here.

## Headless invocation cheatsheet (real flags)

| Engine | family | headless command (read-only + schema) | exit-code gotcha |
|---|---|---|---|
| **codex** | openai | `codex exec --sandbox read-only --output-schema objection-log.schema.json -o "$CVG_OUT" -` (prompt on stdin) | **exits 0 even on failure** → gate the artifact, not `$?` |
| **kimi** | moonshot | `kimi --print --output-format stream-json -p "…"` in an isolated worktree (print mode auto-approves tools) → validate JSON yourself | clean codes: `0` ok · `1` permanent · `75` retry |
| **claude** | anthropic | `claude -p --json-schema "$(cat objection-log.schema.json)" --tools "Read,Grep" --disallowedTools "Edit,Write,mcp__*"` | `stream-json` can **hang** with no TTY → **mandatory `timeout`** |

`claude` is the **fallback only** (same family as the author → weak independence);
default to a cross-family engine (`codex` or `kimi`).

## Provenance stamp (every run — makes the gate un-spoofable)

The adapter stamps the objection-log with: `adversary.{engine_id,model,family,
engine_version,sandbox_mode}`, `prompt_sha256`, `inputs[]` (each plan path +
`sha256` of the bytes it read), `started_at`/`ended_at`, `raw_exit_code`,
`adapter_exit_code`, `timed_out`. The gate re-hashes the live plans and requires a
match — so a plan edited after review, or an adversary that never saw the real
plans, fails.

## `cvg doctor`

Before Pass 4 can dispatch: a per-engine PASS/SKIP table — binary on PATH,
`auth/login status` OK, `--version` captured, a hello-world card round-trips
read-only. Gate requires **≥ 2 engines PASS**, at least one **cross-family**.

## Security

The adversary receives **only** the sealed plan artifacts + the versioned rubric +
the cited grounding pack (spec/ADRs) — **never** the author's authoring transcript
(fresh context defeats sycophancy) — and runs in a **read-only** sandbox / no-write
worktree so it cannot mutate the checkout.
