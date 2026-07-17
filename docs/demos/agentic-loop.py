# agentic-loop.py — a COMPLETE agentic system in ~40 lines.
# The "model" here is FAKE (scripted) so you can watch the LOOP itself.
# Swap fake_model() for an HTTPS call to Anthropic/OpenAI and this IS
# Claude Code / Codex, minus polish. Nothing else changes.
#
# Run from the converge repo root:
#   bash tests/e2e-test-engine/seed.sh && python3 docs/demos/agentic-loop.py
import subprocess, json

def fake_model(transcript):
    """A real model = API call: tokens in -> tokens out.
    It returns EITHER plain text OR a tool-call request (a JSON blob).
    It has no hands - it can only EMIT this data structure."""
    last = transcript[-1]
    if last["role"] == "user":
        return {"type": "tool_call", "name": "bash", "input": {"command":
            "sqlite3 tests/e2e-test-engine/data/toy.db \"SELECT printf('%.2f', sum(paid_amount)) FROM silver_orders WHERE is_paid=1;\""}}
    if last["role"] == "tool_result":
        return {"type": "text",
                "content": "The paid revenue in the fixture is " + last["output"].strip() + "."}

# ------- THE AGENTIC LOOP (this is the whole "agent") -------
transcript = [{"role": "user", "content": "What is the paid revenue in the fixture?"}]
print("USER          :", transcript[0]["content"])
while True:
    move = fake_model(transcript)                    # model "thinks" (tokens out)
    if move["type"] == "text":                       # case a: plain text -> turn over
        print("AGENT (final) :", move["content"]); break
    print("MODEL EMITS   :", json.dumps(move["input"]))          # case b: a REQUEST blob
    r = subprocess.run(move["input"]["command"], shell=True,     # THE HARNESS EXECUTES
                       capture_output=True, text=True)           # (model never touches shell)
    print("HARNESS RAN IT: exit", r.returncode, "| output:", r.stdout.strip())
    transcript.append({"role": "tool_result", "output": r.stdout})  # result -> transcript
    # loop: next iteration the model READS its own tool result and decides again
