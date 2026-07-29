#!/usr/bin/env bash
#
# authoring-format.sh — verify /case AUTHORS to the contract format on a planning
# model. The companion to model-guard.sh: that one asserts a budget model STOPS;
# this one asserts a planning model FOLLOWS — it drafts a `.case.md` that obeys the
# Output Format and branches Story vs Epic by size (the "Authoring: Story vs Epic"
# section of skills/case/SKILL.md).
#
# In headless single-turn mode the Staging Loop writes the draft to `.case.md` and
# stops before the user's commit confirmation, so the draft IS the artifact we
# grade. A trial PASSES when:
#   * the guard did NOT falsely refuse a planning model, AND
#   * `.case.md` exists, AND
#   * STORY case  → exactly one contract: 1 `Acceptance Criteria` heading, a
#                   ```gherkin fence, and the core sections (Problem Statement /
#                   Constraints / Verification / Out of Scope).
#   * EPIC  case  → a decomposition: >=2 `Acceptance Criteria` headings (one per
#                   child story).
#
# Descriptions are deliberately GREENFIELD and self-contained: a fresh `git init`
# has no codebase, so a story that names an existing artifact would (correctly) make
# the architect stop and ask for grounding rather than author. We test the authoring
# format, so we feed it work it can draft from inference alone.
#
# Permission mode is `bypassPermissions` (not acceptEdits): the architect must Read
# the shared rubrics — which live outside the temp repo — and may `bd init`. Under
# acceptEdits those prompt and stall, starving the test of the very Output Format it
# is checking.
#
# Usage:
#   tests/claude/authoring-format.sh [-n TRIALS] [-m MODEL] [-v] [--no-sync]
#     -n  trials per description  (default 2)
#     -m  planning model alias    (default sonnet)
#     -v  verbose: print each trial's raw output and the draft
#     --no-sync  skip overlaying the working tree onto the install
#
# Exit 0 only when every trial passes. Calls the real model — slow, probabilistic.

set -u
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TRIALS=2
MODEL=sonnet
VERBOSE=0
SYNC=1
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -n) TRIALS=$2; shift 2 ;;
    -m) MODEL=$2; shift 2 ;;
    -v) VERBOSE=1; shift ;;
    --no-sync) SYNC=0; shift ;;
    *) echo "usage: $0 [-n TRIALS] [-m MODEL] [-v] [--no-sync]" >&2; exit 2 ;;
  esac
done

# One capability, small surface, greenfield → must come out as a single Story.
STORY_DESCRIPTIONS=(
  "add a slugify utility that turns a title string into a url-safe slug: lowercase, trim, and collapse any run of non-alphanumeric characters into a single hyphen"
  "add a retry helper that re-runs a callable up to N times with a fixed delay between attempts, re-raising the last error if all attempts fail"
)
# Multiple independent capabilities across subsystems → must decompose to an Epic.
EPIC_DESCRIPTIONS=(
  "build user accounts: email+password signup, login with sessions, password reset over email, and an admin page listing all users"
)

CORE_SECTIONS=("## Problem Statement" "## Constraints" "## Acceptance Criteria" "## Verification" "## Out of Scope")

PASS=0
FAIL=0
ERR=0
FAILLOG=$(mktemp)

# $1 = kind (story|epic), $2 = description
# Returns: 0=PASS, 1=FAIL, 2=ERROR (trial never reached the model — inconclusive).
run_trial() {
  local kind="$1" desc="$2" dir out draft
  dir=$(mktemp -d)
  ( cd "$dir" && git init -q )
  out=$( cd "$dir" && timeout 300 claude -p "/case $desc" \
           --model "$MODEL" --permission-mode bypassPermissions 2>&1 )

  local infra
  if infra=$(infra_error "$out"); then
    rm -rf "$dir"
    { printf '\n--- ERROR [%s %s] /case %s\n    %s\n' "$MODEL" "$kind" "$desc" "$infra"; } >>"$FAILLOG"
    [ "$VERBOSE" -eq 1 ] && printf '  ERROR: %s\n' "$infra"
    return 2
  fi

  local -a problems=()

  # The guard must NOT refuse a planning model. (The diagnostic `tier=planning`
  # line isn't reliably surfaced in headless final output, so we don't require it;
  # successful authoring below is itself proof the guard let a planning model pass.
  # The budget-STOP direction is covered by model-guard.sh.)
  grep -qiE 'must run on a planning model' <<<"$out" && problems+=("falsely refused a planning model")

  draft="$dir/.case.md"
  if [ ! -f "$draft" ]; then
    problems+=("no .case.md draft written")
  else
    local body ac_count
    body=$(cat "$draft")
    # Count AC headings at any level (H2 in a single story; children in an epic doc
    # may nest deeper) — robust to decomposition formatting.
    ac_count=$(grep -cE '^#+[[:space:]]+Acceptance Criteria' <<<"$body")
    if [ "$kind" = story ]; then
      local sec
      for sec in "${CORE_SECTIONS[@]}"; do
        grep -qF "$sec" <<<"$body" || problems+=("missing section: $sec")
      done
      grep -qE '```gherkin' <<<"$body" || problems+=("AC not in a \`\`\`gherkin fence")
      grep -qiE '^As an? .+, I want .+,? so that .+' <<<"$body" || problems+=("Problem Statement missing the 'As a …, I want …, so that …' story line")
      grep -qE '^Feature: ' <<<"$body" || problems+=("gherkin block missing its 'Feature:' title line")
      [ "$ac_count" -eq 1 ] || problems+=("expected 1 story (1 AC block), found $ac_count — over/under-decomposed")
    else # epic
      [ "$ac_count" -ge 2 ] || problems+=("expected an epic decomposition (>=2 AC blocks), found $ac_count — not decomposed")
    fi
  fi

  if [ "$VERBOSE" -eq 1 ]; then
    printf '    --- draft (%s) ---\n' "$kind"
    [ -f "$draft" ] && sed 's/^/    | /' "$draft" || printf '    | <none>\n'
  fi
  rm -rf "$dir"

  if [ ${#problems[@]} -eq 0 ]; then
    [ "$VERBOSE" -eq 1 ] && printf '  PASS\n'
    return 0
  fi
  {
    printf '\n--- FAIL [%s %s] /case %s\n' "$MODEL" "$kind" "$desc"
    local p; for p in "${problems[@]}"; do printf '    - %s\n' "$p"; done
    printf '    output:\n'; sed 's/^/    | /' <<<"$out"
  } >>"$FAILLOG"
  [ "$VERBOSE" -eq 1 ] && { local p; for p in "${problems[@]}"; do printf '  FAIL: %s\n' "$p"; done; }
  return 1
}

[ "$SYNC" -eq 1 ] && { sync_plugin || exit 1; }

echo "authoring-format: model=$MODEL trials/desc=$TRIALS  story=${#STORY_DESCRIPTIONS[@]} epic=${#EPIC_DESCRIPTIONS[@]}"

run_set() {  # $1=kind; remaining args = descriptions
  local kind="$1"; shift
  local d i rc
  for d in "$@"; do
    printf '%s: %s\n' "$kind" "$d"
    for i in $(seq 1 "$TRIALS"); do
      printf '  trial %d/%d ... ' "$i" "$TRIALS"
      run_trial "$kind" "$d"; rc=$?
      case "$rc" in
        0) PASS=$((PASS+1)); [ "$VERBOSE" -eq 0 ] && echo PASS ;;
        2) ERR=$((ERR+1));  [ "$VERBOSE" -eq 0 ] && echo ERROR ;;
        *) FAIL=$((FAIL+1)); [ "$VERBOSE" -eq 0 ] && echo FAIL ;;
      esac
    done
  done
}

run_set story "${STORY_DESCRIPTIONS[@]}"
run_set epic  "${EPIC_DESCRIPTIONS[@]}"

TOTAL=$((PASS+FAIL+ERR))
echo
echo "result: $PASS/$TOTAL passed, $FAIL failed, $ERR inconclusive (infra)"
if [ "$FAIL" -gt 0 ]; then
  cat "$FAILLOG"; rm -f "$FAILLOG"; exit 1
fi
if [ "$ERR" -gt 0 ]; then
  cat "$FAILLOG"; rm -f "$FAILLOG"
  echo "no format FAILs, but $ERR trial(s) never reached the model — re-run after the limit/outage clears."
  exit 2
fi
rm -f "$FAILLOG"
echo "all trials followed the authoring format."
