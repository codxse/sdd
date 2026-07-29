#!/usr/bin/env bash
#
# rubrics-sync.sh — keep the Contract Rubrics inlined in each SKILL.md byte-identical
# to shared/contract-rubrics.md, the single source of truth.
#
# /case and /refine are held to one set of contract rubrics, inlined into both
# SKILL.md files rather than read from shared/ at runtime. The rubrics are a hard
# gate — every invocation needs them — so a runtime read saves no context and costs
# a path that cannot be resolved reliably: a relative path in skill prose resolves
# against the *user's* CWD, not the plugin dir, and ${CLAUDE_PLUGIN_ROOT} is
# substituted by Claude Code but not by Codex. Inlined text needs neither.
#
# That trade buys certainty at the price of two copies, so this script is what keeps
# them honest. Unlike the other tests here it never calls a model: it is a pure text
# comparison, fast and deterministic.
#
# Usage:
#   rubrics-sync.sh           verify both skills match the source; exit 1 on drift
#   rubrics-sync.sh --write   regenerate both skills from the source

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mode=verify
case "${1:-}" in
  --write) mode=write ;;
  "")      ;;
  *)       echo "usage: rubrics-sync.sh [--write]" >&2; exit 2 ;;
esac

python3 - "$mode" \
  "$PLUGIN_ROOT/shared/contract-rubrics.md" \
  "$PLUGIN_ROOT/skills/case/SKILL.md" \
  "$PLUGIN_ROOT/skills/refine/SKILL.md" <<'PY'
import pathlib
import sys

mode, source, *targets = sys.argv[1:]

SRC_MARKER = "<!-- BEGIN SHARED -->"
BEGIN = "<!-- BEGIN GENERATED FROM shared/contract-rubrics.md — edit there, then run tests/rubrics-sync.sh --write -->"
END = "<!-- END GENERATED -->"

src = pathlib.Path(source).read_text()
if SRC_MARKER not in src:
    sys.exit(f"{source}: missing {SRC_MARKER}")
body = src.split(SRC_MARKER, 1)[1].strip("\n")

drifted = []
for target in targets:
    path = pathlib.Path(target)
    text = path.read_text()
    if BEGIN not in text or END not in text:
        sys.exit(f"{target}: missing the generated-block markers")

    head, rest = text.split(BEGIN, 1)
    tail = rest.split(END, 1)[1]
    updated = f"{head}{BEGIN}\n\n{body}\n\n{END}{tail}"

    if updated == text:
        continue
    if mode == "write":
        path.write_text(updated)
        print(f"synced {path.name} ({path.parent.name})")
    else:
        drifted.append(target)

if drifted:
    print("Contract Rubrics have drifted from shared/contract-rubrics.md:", file=sys.stderr)
    for target in drifted:
        print(f"  {target}", file=sys.stderr)
    print("\nEdit shared/contract-rubrics.md, then run: tests/rubrics-sync.sh --write", file=sys.stderr)
    sys.exit(1)

print("ok" if mode == "verify" else "done")
PY
