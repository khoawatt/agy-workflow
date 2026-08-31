#!/usr/bin/env bash
# PreInvocation Hook: Injects Auto-Review instructions if enabled in autoreview.json
STATE_FILE="$HOME/.gemini/chatgpt-bridge/autoreview.json"
[ -f "$STATE_FILE" ] || STATE_FILE="$HOME/.config/opencode/chatgpt-bridge/autoreview.json"

is_enabled="false"
if [ -f "$STATE_FILE" ]; then
  if grep -q '"enabled": true' "$STATE_FILE" 2>/dev/null; then
    is_enabled="true"
  fi
fi

if [ "$is_enabled" = "true" ]; then
  cat << 'MSG_EOF'
{
  "injectSteps": [
    {
      "ephemeralMessage": "Auto-review is ENABLED. When you implement a task that introduces code changes, before concluding: 1. Write your normal result summary (Done / What changed / Verification). 2. Follow the `chatgpt-review` skill to send this summary to ChatGPT via `chatgpt-review ask <<'CHATGPT_REVIEW_PROMPT_EOF' ...`. 3. Process the returned verdict (advance to next step on approve, fix on request-changes). Never auto-merge without human approval."
    }
  ]
}
MSG_EOF
else
  echo "{}"
fi
