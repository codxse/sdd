#!/usr/bin/env bash

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - \
  "$PLUGIN_ROOT/skills/orchestrate/SKILL.md" \
  "$PLUGIN_ROOT/skills/milestone/SKILL.md" \
  "$PLUGIN_ROOT/skills/validate/SKILL.md" \
  "$PLUGIN_ROOT/.claude-plugin/plugin.json" \
  "$PLUGIN_ROOT/.codex-plugin/plugin.json" \
  "$PLUGIN_ROOT/../../.claude-plugin/marketplace.json" \
  "$PLUGIN_ROOT/../../.agents/plugins/marketplace.json" \
  "$PLUGIN_ROOT/../../kimi.plugin.json" \
  "$PLUGIN_ROOT/tests/claude/model-guard.sh" \
  "$PLUGIN_ROOT/tests/codex/model-guard.sh" \
  "$PLUGIN_ROOT/tests/kimi/model-guard.sh" \
  "$PLUGIN_ROOT/tests/opencode/model-guard.sh" \
  "$PLUGIN_ROOT/../../README.md" \
  "$PLUGIN_ROOT/../../.claude-plugin/marketplace.json" <<'PY'
import json
import pathlib
import sys

orchestrate = pathlib.Path(sys.argv[1]).read_text()
milestone = pathlib.Path(sys.argv[2]).read_text()
validate = pathlib.Path(sys.argv[3]).read_text()
manifest_paths = [pathlib.Path(value) for value in sys.argv[4:9]]
guard_paths = [pathlib.Path(value) for value in sys.argv[9:13]]
readme = pathlib.Path(sys.argv[13]).read_text()
claude_marketplace = json.loads(pathlib.Path(sys.argv[14]).read_text())

required_orchestrate = [
    "<id> [<id> ...]",
    "input order",
    "The ordered scope is the priority list",
    "orchestrate/<anchor>-<hash8>",
    "git hash-object --stdin",
    "There is no legacy epic branch mode",
    "GitHub -> require authenticated `gh`",
    "GitLab -> require authenticated `glab`",
    "git-only mode",
    "including `--dry-run` and `--finalize`, requires **frontier**",
    "`--finalize` goes directly to **Finalize A Merged Run**",
    "epic independently. Close that exact epic",
    "published release-head SHA",
    "publication phase `release-ready`",
    "A `release-ready` or `pushed` resume verifies the run branch HEAD equals",
    "<release-head>:refs/heads/<run-branch>",
    "invoke `/milestone --sync` once",
    "Never use `git add .`",
    "git -C <main-root> check-ignore -- .milestone.md",
    "positively identified GitHub/GitLab",
    "repository-scoped `gh` or `glab` queries",
    "source branch, target base, and published release-head SHA",
]

required_milestone = [
    "local-only project memory and must never be committed",
    "`/.milestone.md`",
    "git -C <main-root> rev-parse --git-path info/exclude",
    "git -C <main-root> check-ignore -- .milestone.md",
    "Never modify the committed `.gitignore`",
    "recompute the reconciliation once",
    "never writes to bd",
]

required_validate = [
    "provisional orchestration branch",
    "final PR/MR",
]

for label, text, required in [
    ("orchestrate", orchestrate, required_orchestrate),
    ("milestone", milestone, required_milestone),
    ("validate", validate, required_validate),
]:
    missing = [item for item in required if item not in text]
    if missing:
        print(f"{label} contract missing:", file=sys.stderr)
        for item in missing:
            print(f"  {item}", file=sys.stderr)
        sys.exit(1)

for forbidden in [
    "Every run uses `epic/",
    "git checkout -b epic/",
    "Unknown forge -> no supported forge CLI",
]:
    if forbidden in orchestrate:
        sys.exit(f"orchestrate contract retains forbidden behavior: {forbidden}")

if "Never use `git add .`,\n`git add -A`" not in orchestrate:
    sys.exit("orchestrate contract must explicitly forbid broad staging")

versions = []
for path in manifest_paths:
    data = json.loads(path.read_text())
    if path.name == "marketplace.json":
        versions.append(next(plugin["version"] for plugin in data["plugins"] if plugin["name"] == "sdd"))
    else:
        versions.append(data["version"].split("+", 1)[0])
if versions != ["3.4.0"] * len(versions):
    sys.exit(f"publication versions drifted: {versions}")

for path in guard_paths:
    text = path.read_text()
    if "orchestrate/*" not in text:
        sys.exit(f"{path}: does not watch orchestrate/* side effects")
    if path.parent.name == "opencode":
        marker = 'run_set "frontier/finalize"'
    else:
        marker = 'POSITIVE_CMDS=('
        positive = text.split(marker, 1)[1].split(")", 1)[0] if marker in text else ""
        if "--finalize" not in positive:
            sys.exit(f"{path}: frontier-positive commands do not exercise --finalize")
        continue
    if marker not in text or "--finalize" not in text.split(marker, 1)[1].split("\n", 1)[0]:
        sys.exit(f"{path}: frontier-positive commands do not exercise --finalize")

if "Unknown forges stop" not in readme or "matching\n  CLI is unavailable or unauthenticated" not in readme:
    sys.exit("README git-only forge boundary drifted")

sdd_entry = next(plugin for plugin in claude_marketplace["plugins"] if plugin["name"] == "sdd")
if "explicit post-merge --finalize" not in sdd_entry["description"]:
    sys.exit("Claude marketplace must name explicit --finalize")

print("ok")
PY
