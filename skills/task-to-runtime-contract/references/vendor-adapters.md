# Vendor adapters

The profile and portable guards are the contract. Vendor adapters translate
that contract into runtime-specific controls; they never redefine it.

| Runtime | Native control | Portable fallback |
|---|---|---|
| Claude Code | `PreToolUse` hook calls `guard-tool-input.py` | diff guard before settlement |
| Codex | workspace sandbox plus scoped instructions | diff guard before settlement |
| Kimi | permission mode or hook when available | diff guard before settlement |
| Any/simpler agent | surrounding runner passes candidate paths when possible | diff guard before settlement |

Each generated adapter manifest records:

- the execution-profile path;
- candidate-path and postflight commands;
- whether pre-tool prevention is supported;
- the native mechanism expected from the runtime;
- the portable fail-closed fallback.

Adapter manifests are evidence and integration inputs. They do not claim a
vendor configuration was installed. A dispatcher owns that final runtime
translation and must fail closed when it cannot provide the declared control.

