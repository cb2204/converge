# `.cvg/people-map` — routing a spec to a tracker person

A spec says *what kind of executor* it needs — `execution_backend: claude`,
`agent: python-developer` — never *who*. The **people-map** is the local, opt-in
lookup that turns those routing choices into a tracker person, so `register.sh`
can seed a Linear issue's `assigneeId` and `subscriberIds`.

It is **optional**. With no people-map, assignee/subscriber resolution is a
fail-soft miss and the issue registers without them — the base projection is
unchanged. Nothing here ever gates a registration.

## Format

Plain `KEY=VALUE` lines, one per mapping — the same shape and guarantees as
`.cvg/config`: greppable, bash-3.2-safe, idempotent replace-or-append.

```
# .cvg/people-map
agent:python-developer=ana@owshq.com
backend:claude=luan@owshq.com
backend:codex=luan@owshq.com
default=luan@owshq.com
```

**Keys** are routing choices, matched against a spec's frontmatter:

| key | matches | example |
|-----|---------|---------|
| `agent:<role>` | the spec's `agent:` (its needed role) | `agent:python-developer` |
| `backend:<engine>` | the spec's `execution_backend:` (which harness runs it) | `backend:claude` |
| `default` | the catch-all when nothing more specific maps | `default` |

**Values** are a Linear **email** or **user uuid**. A uuid passes straight
through; an email is resolved via `users(filter:{ email:{ eq } })` to a uuid at
register time (`_ln_resolve_user`). An email that matches no active user is a
fail-soft skip.

## Choices, never credentials

An email or a user id is a **routing choice**, not a secret — the same class of
non-secret as the Linear team key or the repo base URL. So the people-map is
safe to commit and `cvg` bridges it into the adapter env. What crosses the
boundary is **only the file path** (`TSI_PEOPLE_MAP`), never a Linear API key:
the referee holds no credentials (see the SKILL.md trust model and
[adapter-contract.md](./adapter-contract.md)). If `cvg` can't see a secret, it
can't leak one.

## How register resolves an assignee

The driver picks the **most specific** key that carries signal, and the adapter
resolves it — falling back to `default` when the specific key is unmapped:

```
agent:<role>   (if agent is a real role, not "any"/none)
     ↓ else
backend:<engine>   (if execution_backend is set)
     ↓ else
default
```

So `agent: python-developer` wins over `execution_backend: claude`; a spec whose
`agent: any` falls back to its backend; a spec with neither still picks up the
`default` mapping if one exists. Resolution and the `default` fallback both live
in the adapter (`_ln_people_map_lookup` → `_ln_resolve_user`), so the driver just
supplies one key and the projection stays portable — github/jira ignore it.

`assigneeId` is **seed-once** (applied on create only), so re-registering never
re-assigns an issue a human has since re-routed on the board.

## Subscribers

`subscriberIds` is derived from the spec's `signed_off_by` (comma/space
separated — each token resolved independently, unresolvable ones skipped). Unlike
the assignee, subscribers are **union-merged**: the adapter reads the issue's
current subscribers and adds to them, so a human who subscribed on the board is
never dropped by a re-register.

## Managing it

```
cvg setup people                      # discover tracker members (name + email)
cvg setup people --map backend:claude=you@org.com
cvg setup people --map agent:coder=you@org.com --map default=you@org.com
```

`cvg setup people` (no flags / `--list`) calls the adapter's `users` verb to list
the workspace's members as a ready-to-paste block; `--map KEY=VALUE` writes
idempotently. Coverage shows on `cvg setup` as an informational row — it never
blocks `READY`, because an unmapped assignee is fail-soft by design.
