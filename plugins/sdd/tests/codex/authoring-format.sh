#
# authoring-format.sh — verify /specify AUTHORS to the contract format on a
# frontier model, on Codex. The Codex twin of tests/claude/authoring-format.sh —
# same property, same grading, different host.
#
# The companion to model-guard.sh: that one asserts a budget model STOPS; this
# one asserts a frontier model FOLLOWS — it drafts a `.spec.md` that obeys the
# Output Format and branches Story vs Epic by size (the "Authoring: Story vs
# Epic" section of skills/specify/SKILL.md).
#
# In headless single-turn mode the Staging Loop writes the draft to `.spec.md`
# and stops before the user's commit confirmation, so the draft IS the artifact
# we grade. A trial PASSES when:
#   * the guard did NOT falsely refuse a frontier model, AND
#   * `.spec.md` exists, AND
#   * STORY case  → exactly one contract: 1 `Acceptance Criteria` heading, a
#                   ```gherkin fence, and the core sections (Problem Statement /
#                   Constraints / Verification / Complexity / Out of Scope).
#   * EPIC  case  → a decomposition: >=2 `Acceptance Criteria` headings (one per
#                   child story) and a well-formed Complexity call per child.
#
# Both cases also assert the 3.0.0 rubric changes hold in the draft: the
# Complexity call names a rung + an effort on the low/high/max scale (never
# `medium` — that names a rung), and nothing from the removed Problem Types
# taxonomy (a `Deliverable Format` section) or the retired `planning` tier
# vocabulary survives.
#
# Descriptions are GREENFIELD but name the project's language, and each trial seeds a
# minimal Python fixture first: the 3.0.0 Socratic loop asks about any
# contract-changing unknown — and in a bare `git init` the runtime *is* one (a
# correct 3.0.0 run asks "which language?" instead of drafting). The fixture plus an
# explicit language leaves nothing the loop must ask, so the draft is still the
# artifact we grade.
#
# Usage:
#   tests/codex/authoring-format.sh [-n TRIALS] [-m MODEL] [-v] [--no-sync]
#     -n  trials per description  (default 2)
#     -m  frontier model          (default gpt-5.6-sol)
#     -v  verbose: print each trial's raw output and the draft
#     --no-sync  skip overlaying the working tree onto the install
#
# Exit 0 only when every trial passes. Calls the real model — slow, probabilistic.

set -u
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TRIALS=2
MODEL=gpt-5.6-sol
VERBOSE=0
SYNC=1
while [ $# -gt 0 ]; do
  case "$1" in
    -n) TRIALS=$2; shift 2 ;;
    -m) MODEL=$2; shift 2 ;;
    -v) VERBOSE=1; shift ;;
    --no-sync) SYNC=0; shift ;;
    *) echo "usage: $0 [-n TRIALS] [-m MODEL] [-v] [--no-sync]" >&2; exit 2 ;;
  esac
done

# One capability, small surface → must come out as a single Story.
STORY_DESCRIPTIONS=(
  "add a slugify utility to the Python project that turns a title string into a url-safe slug: lowercase, trim, and collapse any run of non-alphanumeric characters into a single hyphen; characters outside a-z and 0-9 after lowercasing count as separators, never transliterated"
  "add a retry helper to the Python project that re-runs a callable up to N times with a fixed delay between attempts, re-raising the last error if all attempts fail; any exception triggers a retry"
)
# Multiple independent capabilities across subsystems → must decompose to an Epic.
EPIC_DESCRIPTIONS=(
  "build user accounts for the Python Flask web app with SQLite storage: email+password signup, login with server-side sessions, password reset via a reset link printed to the server log (no email service in this dev setup), and an admin page listing all users; the first admin is created by a CLI command, never through public signup"
)

# A minimal fixture so the project's language and layout are discoverable from the
# codebase itself — the Socratic loop's "read before you ask" answers the runtime
# question from this instead of asking it.
seed_fixture() {  # $1 = repo dir
  printf '[project]\nname = "fixture-app"\nversion = "0.1.0"\n' > "$1/pyproject.toml"
  mkdir -p "$1/src"
}

CORE_SECTIONS=("## Problem Statement" "## Constraints" "## Acceptance Criteria" "## Verification" "## Complexity" "## Out of Scope")

# The Complexity call as the Output Format template states it. Written with `.*`
# for the `·` separator so the match is locale-robust (C vs UTF-8).
SOLVER_RE='^Recommended Solver: (budget|medium|frontier).*effort (low|high|max)'

PASS=0
FAIL=0
ERR=0
FAILLOG=$(mktemp)

# $1 = kind (story|epic), $2 = description
# Returns: 0=PASS, 1=FAIL, 2=ERROR (trial never reached the model).
run_trial() {
  local kind="$1" desc="$2" dir out rc draft
  dir=$(mktemp -d)
  ( cd "$dir" && git init -q )
  seed_fixture "$dir"
  out=$( cd "$dir" && run_clean_env timeout 300 codex exec \
           --ephemeral \
           --sandbox workspace-write \
           --model "$MODEL" \
           --dangerously-bypass-hook-trust \
           "\$sdd:specify $desc" </dev/null 2>&1 )
  rc=$?

  local infra
  if [ "$rc" -ne 0 ]; then
    rm -rf "$dir"
    infra=$(infra_error "$out" || true)
    [ -n "$infra" ] || infra="codex exec exited $rc"
    { printf '\n--- ERROR [%s %s] /specify %s\n    %s\n' "$MODEL" "$kind" "$desc" "$infra"; } >>"$FAILLOG"
    [ "$VERBOSE" -eq 1 ] && printf '  ERROR: %s\n' "$infra"
    return 2
  fi
  if infra=$(infra_error "$out"); then
    rm -rf "$dir"
    { printf '\n--- ERROR [%s %s] /specify %s\n    %s\n' "$MODEL" "$kind" "$desc" "$infra"; } >>"$FAILLOG"
    [ "$VERBOSE" -eq 1 ] && printf '  ERROR: %s\n' "$infra"
    return 2
  fi

  local -a problems=()

  # No false-refusal grep on this host: a `codex exec` transcript echoes the SKILL.md
  # the model read, so matching "must run on a frontier model" hits the skill's own
  # prose (the same trap model-guard.sh documents). A real false refusal still fails
  # here as "no .spec.md draft written", with the stop message visible under -v. The
  # below-frontier direction is covered by model-guard.sh.

  draft="$dir/.spec.md"
  if [ ! -f "$draft" ]; then
    problems+=("no .spec.md draft written")
  else
    local body ac_count solver_count
    body=$(cat "$draft")
    ac_count=$(grep -cE '^#+[[:space:]]+Acceptance Criteria' <<<"$body")
    grep -qiF "Deliverable Format" <<<"$body" && problems+=("draft carries a removed 'Deliverable Format' section")
    grep -qiE '\bplanning (model|tier|rung)' <<<"$body" && problems+=("draft uses retired 'planning' tier vocabulary")
    grep -qE 'effort[ :=*]+medium\b' <<<"$body" && problems+=("effort scale regressed to 'medium' — that names a rung; the scale is low/high/max")
    if [ "$kind" = story ]; then
      local sec
      for sec in "${CORE_SECTIONS[@]}"; do
        grep -qF "$sec" <<<"$body" || problems+=("missing section: $sec")
      done
      grep -qE '```gherkin' <<<"$body" || problems+=("AC not in a \`\`\`gherkin fence")
      # The template's own form is a three-line fenced story line, so join before
      # matching: accept both the one-line and the three-line spellings.
      tr '\n' ' ' <<<"$body" | grep -qiE 'As an? [^,]+, +I want [^,]+,? +so that ' || problems+=("Problem Statement missing the 'As a …, I want …, so that …' story line")
      grep -qE '^Feature: ' <<<"$body" || problems+=("gherkin block missing its 'Feature:' title line")
      grep -qE "$SOLVER_RE" <<<"$body" || problems+=("Complexity call missing or malformed — want 'Recommended Solver: <budget|medium|frontier> · effort <low|high|max>'")
      [ "$ac_count" -eq 1 ] || problems+=("expected 1 story (1 AC block), found $ac_count — over/under-decomposed")
    else # epic
      [ "$ac_count" -ge 2 ] || problems+=("expected an epic decomposition (>=2 AC blocks), found $ac_count — not decomposed")
      solver_count=$(grep -cE "$SOLVER_RE" <<<"$body")
      [ "$solver_count" -ge 2 ] || problems+=("expected a Complexity call per child story (>=2 well-formed), found $solver_count")
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
    printf '\n--- FAIL [%s %s] /specify %s\n' "$MODEL" "$kind" "$desc"
    local p; for p in "${problems[@]}"; do printf '    - %s\n' "$p"; done
    printf '    output:\n'; sed 's/^/    | /' <<<"$out"
  } >>"$FAILLOG"
  [ "$VERBOSE" -eq 1 ] && { local p; for p in "${problems[@]}"; do printf '  FAIL: %s\n' "$p"; done; }
  return 1
}

[ "$SYNC" -eq 1 ] && { sync_plugin || exit 1; }

if ! codex debug models 2>/dev/null | grep -qF "\"slug\":\"$MODEL\""; then
  echo "authoring-format (codex): model '$MODEL' is not present in the active Codex catalog." >&2
  exit 2
fi

echo "authoring-format (codex): model=$MODEL trials/desc=$TRIALS  story=${#STORY_DESCRIPTIONS[@]} epic=${#EPIC_DESCRIPTIONS[@]}"

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
