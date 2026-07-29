#!/bin/sh
# Give a Kimi Code session the model identity the host never states.
#
# Kimi is the one host with no model ID anywhere the model can read: its system
# prompt names only "Kimi Code CLI", and no hook payload carries a `model` field
# (SessionStart gives hook_event_name/session_id/cwd/source only). Without an ID
# every gated skill classifies `unsure` — and models do not stop there, they guess:
# observed failures include adopting `default_model` from config.toml, and a budget
# `kimi-for-coding` session reasoning "Kimi Code CLI runs on k3, k3 is frontier" and
# then authoring to bd. Both directions of the Model Guard break on the same gap.
#
# UserPromptSubmit, not SessionStart: it is the only Kimi hook documented to append
# its output to the model's context ("returned text is appended to context"), and it
# is the only event whose payload carries the `session_id` this needs.
#
# The ID comes from `modelAlias` in the session's own record under
# $KIMI_CODE_HOME/sessions/*/<session_id>/. Two sources were tried first and are
# wrong, so do not "simplify" back to them:
#   * The launching process's argv — kimi overwrites its own argv with a bare
#     `kimi-code`, erasing `-m`. It survives only when something wraps the process
#     (the test harness's `timeout`), never on a real launch.
#   * `default_model` from config.toml — that is the session's model only when the
#     user did not override it. Asserting it anyway is worse than staying silent: it
#     tells a budget session it is frontier, turning "stop" into "author".
# The last `modelAlias` wins, so an interactive `/model` switch is picked up too.
#
# Fail closed: print nothing when the ID cannot be established. A silent hook leaves
# the session `unsure`, which the gated skills already handle by stopping. A confident
# wrong answer does not fail safe.

set -eu

payload=$(cat 2>/dev/null || true)
session_id=$(printf '%s' "$payload" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
[ -n "$session_id" ] || exit 0

session_dir=""
for candidate in "${KIMI_CODE_HOME:-$HOME/.kimi-code}"/sessions/*/"$session_id"; do
  [ -d "$candidate" ] && { session_dir=$candidate; break; }
done
[ -n "$session_dir" ] || exit 0

model=$(grep -rhoE '"modelAlias"[[:space:]]*:[[:space:]]*"[^"]*"' "$session_dir" 2>/dev/null |
        sed -n 's/.*"\([^"]*\)"$/\1/p' | tail -1)
[ -n "$model" ] || exit 0

printf 'Host-reported exact model ID: `%s`. Treat this session fact as authoritative for model-tier classification.\n' "$model"
