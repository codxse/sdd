#!/usr/bin/env bash
#
# socratic-loop.sh — verify /specify QUESTIONS a vague description instead of
# writing it up. The 3.0.0 Socratic loop: the description is the *opening*
# position, and the architect must push on every vague word ("fast", "secure",
# "handles errors") until the contract is settled — not invent the observable
# itself.
#
# The companion to authoring-format.sh: that one feeds fully-specified
# descriptions and asserts the architect drafts; this one feeds descriptions
# seeded with a vague word and asserts the architect ASKS FIRST. In headless
# single-turn mode there is no one to answer, so a correct run stops at its
# question — a trial PASSES when:
#   * the guard did NOT falsely refuse a frontier model, AND
#   * the output asks at least one question, AND
#   * the questioning carries a recommended answer (the rubric: "one question at
#     a time, each carrying your recommended answer"), AND
#   * nothing was authored — no `.spec.md` draft, no bd backlog. Drafting past
#     the vague word is exactly the failure this harness exists to catch.
#
# The recommendation check is a coarse regex over common phrasings — a trial can
# ask well and still trip it on unusual wording. Re-run with -v before believing
# a FAIL on that clause alone.
#
# Multi-turn probing (answer the question, assert the loop then converges to a
# draft) is deliberately out of scope — deferred.
#
# Manual-only harness: not wired into CI.
#
# Usage:
#   tests/claude/socratic-loop.sh [-n TRIALS] [-m MODEL] [-v] [--no-sync]
#     -n  trials per description  (default 3)
#     -m  frontier model alias    (default opus)
#     -v  verbose: print each trial's raw output
#     --no-sync  skip overlaying the working tree onto the install
#
# Exit 0 only when every trial passes. Calls the real model — slow, probabilistic.

set -u
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TRIALS=3
MODEL=opus
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

# Each description is self-contained enough that the architect COULD draft it by
# inventing the missing observable — that temptation is the test. The vague word
# in each is an unwritten AC the Socratic loop must push on first.
DESCRIPTIONS=(
  "add an endpoint that returns user statistics and make it fast"
  "add a cli command that syncs local files to the remote server and handles errors properly"
  "make the search feature secure"
)

# "Carries your recommended answer" — common phrasings. Coarse on purpose; see
# the header note.
RECOMMEND_RE='recommend|suggest|propos|I'"'"'d (go|default)|default (to|would)|my (pick|default)'

PASS=0
FAIL=0
ERR=0
FAILLOG=$(mktemp)

# Returns: 0=PASS, 1=FAIL, 2=ERROR (trial never reached the model — inconclusive).
run_trial() {
  local desc="$1" dir out
  dir=$(mktemp -d)
  ( cd "$dir" && git init -q )
  out=$( cd "$dir" && run_clean_env timeout 300 claude -p "/specify $desc" \
           --model "$MODEL" --permission-mode acceptEdits 2>&1 )

  local infra
  if infra=$(infra_error "$out"); then
    rm -rf "$dir"
    { printf '\n--- ERROR [%s] /specify %s\n    %s\n' "$MODEL" "$desc" "$infra"; } >>"$FAILLOG"
    [ "$VERBOSE" -eq 1 ] && printf '  ERROR: %s\n' "$infra"
    return 2
  fi

  local -a problems=()

  grep -qiE 'must run on a frontier model' <<<"$out" && problems+=("falsely refused a frontier model")

  # The load-bearing assertion: authored nothing. A written draft means the
  # architect invented the observable the vague word was hiding.
  [ -f "$dir/.spec.md" ] && problems+=("wrote .spec.md past the vague word")
  [ -d "$dir/.beads" ]   && problems+=("created a bd backlog past the vague word")

  grep -q '?' <<<"$out" || problems+=("asked no question — took the description at face value")
  grep -qiE "$RECOMMEND_RE" <<<"$out" || problems+=("questioning carries no recommended answer (coarse check — eyeball with -v)")

  rm -rf "$dir"

  if [ ${#problems[@]} -eq 0 ]; then
    [ "$VERBOSE" -eq 1 ] && printf '  PASS\n'
    return 0
  fi
  {
    printf '\n--- FAIL [%s] /specify %s\n' "$MODEL" "$desc"
    local p; for p in "${problems[@]}"; do printf '    - %s\n' "$p"; done
    printf '    output:\n'; sed 's/^/    | /' <<<"$out"
  } >>"$FAILLOG"
  [ "$VERBOSE" -eq 1 ] && { local p; for p in "${problems[@]}"; do printf '  FAIL: %s\n' "$p"; done; }
  return 1
}

[ "$SYNC" -eq 1 ] && { sync_plugin || exit 1; }

echo "socratic-loop: model=$MODEL trials/desc=$TRIALS  descriptions=${#DESCRIPTIONS[@]}"

for desc in "${DESCRIPTIONS[@]}"; do
  printf 'desc: %s\n' "$desc"
  for i in $(seq 1 "$TRIALS"); do
    printf '  trial %d/%d ... ' "$i" "$TRIALS"
    run_trial "$desc"; rc=$?
    case "$rc" in
      0) PASS=$((PASS+1)); [ "$VERBOSE" -eq 0 ] && echo PASS ;;
      2) ERR=$((ERR+1));  [ "$VERBOSE" -eq 0 ] && echo ERROR ;;
      *) FAIL=$((FAIL+1)); [ "$VERBOSE" -eq 0 ] && echo FAIL ;;
    esac
  done
done

TOTAL=$((PASS+FAIL+ERR))
echo
echo "result: $PASS/$TOTAL passed, $FAIL failed, $ERR inconclusive (infra)"
if [ "$FAIL" -gt 0 ]; then
  cat "$FAILLOG"; rm -f "$FAILLOG"; exit 1
fi
if [ "$ERR" -gt 0 ]; then
  cat "$FAILLOG"; rm -f "$FAILLOG"
  echo "no socratic FAILs, but $ERR trial(s) never reached the model — re-run after the limit/outage clears."
  exit 2
fi
rm -f "$FAILLOG"
echo "all trials questioned the vague word before authoring."
