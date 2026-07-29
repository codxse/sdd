#!/bin/sh
# Preserve the shared workflow primer on every host. Codex hook payloads also
# include the active model slug; surface it because Codex's generic base prompt
# names only the GPT-5 family rather than the exact selected model.

set -eu

payload=$(cat)
model=$(printf '%s\n' "$payload" | sed -n 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
plugin_root=${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-}}

cat "$plugin_root/hooks/session-primer.md"
if [ -n "$model" ]; then
  printf '\nHost-reported exact model ID: `%s`. Treat this session fact as authoritative for model-tier classification.\n' "$model"
fi
