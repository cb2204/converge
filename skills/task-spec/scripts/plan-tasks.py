#!/usr/bin/env python3
"""plan-tasks.py — Pass 5 DRY RUN: what would be created, and why, before anything is.

WHY THIS EXISTS
Pass 5 turns accepted legs into signed Task-Specs, and until now the only way to
see what that produced was to produce it. `cvg tasks new` writes one spec at a
time, so a plan set of eleven legs became eleven irreversible-feeling steps with no
way to review the shape first. The owner asked the obvious question — "show me what
you are about to create, and why" — and the answer was: no such surface.

IT DERIVES, IT DOES NOT INVENT. Every leg already declares its own task list at
Pass 3, under `## Yields at Pass 5B (named units, not specified here)`, and its own
reason under `## Responsibility`. This reads those, in leg order, and shows the
work Pass 5 would do. Nothing here is a suggestion the plans do not already carry;
if a preview line looks wrong, the LEG is wrong, and that is the point — a dry run
that invented plausible tasks would hide exactly the defect worth catching.

Read-only by construction: it opens plan files and writes nothing.

Usage:
  plan-tasks.py --dir <swimlanes-dir> [--lane <seam>]

Token (last line): TASKS_PLAN=OK | TASKS_PLAN=EMPTY | TASKS_PLAN=USAGE_ERROR
Exit: 0 ok · 1 nothing to plan · 2 usage error
Python 3.8+, stdlib only.
"""
import argparse
import glob
import os
import re
import sys


def die(msg, token="TASKS_PLAN=USAGE_ERROR", code=2):
    print(f"error: {msg}", file=sys.stderr)
    print(token)
    sys.exit(code)


def frontmatter(text):
    """Parse the leading --- block. Deliberately shallow: these are flat scalars
    and short lists, and a YAML dependency would put a pip install between an
    owner and a preview."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    out = {}
    for line in text[3:end].splitlines():
        if ":" not in line or line.strip().startswith("#"):
            continue
        k, v = line.split(":", 1)
        out[k.strip()] = v.strip()
    return out


def section(text, name):
    """Body of '## <name>' up to the next '## '."""
    m = re.search(rf"^##\s+{re.escape(name)}[^\n]*\n(.*?)(?=^##\s|\Z)",
                  text, re.M | re.S)
    return m.group(1).strip() if m else ""


def first_sentence(body, limit=240):
    """The leg's reason, trimmed. Comments and blockquotes are guidance for the
    author, not the why, so they are dropped."""
    lines = [l for l in body.splitlines()
             if l.strip() and not l.strip().startswith(("<!--", ">", "|", "-->"))]
    prose = " ".join(lines)
    prose = re.sub(r"\s+", " ", prose).strip()
    if not prose:
        return "(no Responsibility prose — the leg does not say why it exists)"
    cut = re.split(r"(?<=[.;])\s", prose)
    text = cut[0] if cut else prose
    if len(text) > limit:
        text = text[:limit].rsplit(" ", 1)[0] + "…"
    return text


def bullets(body):
    out = []
    for line in body.splitlines():
        s = line.strip()
        if s.startswith(("- ", "* ")):
            out.append(re.sub(r"\s+", " ", s[2:]).strip())
        elif out and s and not s.startswith(("<!--", "-->", "#")):
            out[-1] += " " + s  # continuation of a wrapped bullet
    return [b for b in out if b and not b.startswith("<")]


def slugify(s):
    s = re.sub(r"[^a-z0-9]+", "-", s.lower())
    return re.sub(r"^-+|-+$", "", s)[:40]


def lane_dirs(root):
    """A lane is a dir holding a lane PRD — _lane.md canonical, <name>.plan.md
    legacy. Same rule the Pass 3/4 gates use, so a preview cannot disagree with
    them about what a swimlane is."""
    out = []
    for d in sorted(glob.glob(os.path.join(root, "*", ""))):
        base = os.path.basename(os.path.dirname(d))
        if base.startswith("."):
            continue
        prd = os.path.join(d, "_lane.md")
        if not os.path.exists(prd):
            legacy = sorted(glob.glob(os.path.join(d, "*.plan.md")))
            if not legacy:
                continue
            prd = legacy[-1]
        out.append((base, d, prd))
    return out


def leg_files(d):
    """leg-NN-*.md canonical, swimlane-<seam>-leg-NN-*.md legacy; ordered by NN."""
    files = sorted(glob.glob(os.path.join(d, "leg-[0-9][0-9]-*.md"))) + \
            sorted(glob.glob(os.path.join(d, "*-leg-[0-9][0-9]-*.md")))
    def num(p):
        m = re.search(r"leg-(\d\d)", os.path.basename(p))
        return int(m.group(1)) if m else 99
    return sorted(set(files), key=num)


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--dir", required=True)
    ap.add_argument("--lane")
    ap.add_argument("--help", "-h", action="store_true")
    try:
        args = ap.parse_args()
    except SystemExit:
        die("usage: plan-tasks.py --dir <swimlanes-dir> [--lane <seam>]")
    if args.help:
        print(__doc__)
        print("TASKS_PLAN=OK")
        return 0
    if not os.path.isdir(args.dir):
        die(f"no swimlane tree at {args.dir}/ — run Pass 3 first")

    lanes = lane_dirs(args.dir)
    if args.lane:
        lanes = [l for l in lanes if l[0] == args.lane]
        if not lanes:
            die(f"no lane named {args.lane!r} under {args.dir}/")
    if not lanes:
        print(f"no swimlanes under {args.dir}/ — nothing to plan.", file=sys.stderr)
        print("TASKS_PLAN=EMPTY")
        return 1

    print("cvg tasks plan · DRY RUN — nothing is written")
    print(f"  source: {args.dir}/   ({len(lanes)} lane(s))")
    print("  Every unit below is declared by its leg's own 'Yields at Pass 5B'")
    print("  section. This derives; it never invents. A wrong line here means a")
    print("  wrong leg — fix Pass 3, do not paper over it at Pass 5.")

    total_units = 0
    total_legs = 0
    commands = []
    for seam, d, _prd in lanes:
        legs = leg_files(d)
        print(f"\n═══ lane · {seam}  ({len(legs)} leg(s)) ═══")
        if not legs:
            print("  (no legs — this lane yields nothing at Pass 5)")
        for lf in legs:
            text = open(lf, encoding="utf-8", errors="replace").read()
            fm = frontmatter(text)
            key = fm.get("leg", "?")
            tech = fm.get("tech", "")
            status = fm.get("status", "?")
            appetite = first_sentence(section(text, "Appetite"), 40) or "?"
            deps = fm.get("depends_on", "[]")
            why = first_sentence(section(text, "Responsibility"))
            units = bullets(section(text, "Yields at Pass 5B"))
            total_legs += 1

            print(f"\n  ▸ {key}  [{tech}]  status={status}  appetite={appetite}")
            print(f"    why      : {why}")
            print(f"    dep edges: {deps}")
            if not units:
                print("    WOULD CREATE: nothing — this leg declares no Yields section.")
                print("                  Pass 5 cannot decompose a leg that never said")
                print("                  what it becomes; that is a Pass 3 gap.")
                continue
            for i, u in enumerate(units, 1):
                slug = slugify(f"{seam}-{tech or 'unit'}-{i}")
                total_units += 1
                print(f"    would create [{i}] {slug}")
                print(f"                     from: {u}")
                commands.append((slug, key))

    print(f"\n─── summary ───")
    print(f"  {total_legs} leg(s) → {total_units} proposed Task-Spec(s)")
    if total_units == 0:
        print("  Nothing would be created. Every leg is missing its Yields section.")
        print("TASKS_PLAN=EMPTY")
        return 1
    print("\n  the commands this becomes (each still gates and seals on its own):")
    for slug, key in commands:
        print(f"    cvg tasks new {slug}     # cites {key}")
    print("\n  NOT DONE by this preview: no spec written, no eval authored, no")
    print("  sizing verdict, no HMAC seal. `cvg tasks new` then `cvg tasks validate`")
    print("  then `cvg tasks gate --stamp` remain the real gates; a dry run that")
    print("  implied otherwise would be worse than no dry run.")
    print("TASKS_PLAN=OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
