#!/usr/bin/env bash
# Safely merge the open Pull Request for the current branch, but ONLY after
# every safety condition is verified (fail closed).
#
# Safety conditions:
#   1. Current branch has EXACTLY ONE matching OPEN PR in this repo.
#   2. PR is mergeable (no conflicts).
#   3. A ChatGPT review approval is recorded (verdict "approve") with headSha == HEAD.
#   4. Every required status check on the PR is SUCCESS.
#   5. The final merge is HEAD-atomic: `gh pr merge --match-head-commit <HEAD>`.
#
# Accepts NO arguments to prevent privilege escalation.

set -euo pipefail

BRIDGE="chatgpt-review"
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required." >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "ERROR: gh CLI is required." >&2; exit 1; }
command -v "$BRIDGE" >/dev/null 2>&1 || {
  if [ -x "$HOME/.local/bin/chatgpt-review" ]; then
    BRIDGE="$HOME/.local/bin/chatgpt-review"
  elif [ -x "$HOME/.config/opencode/chatgpt-bridge/bin/chatgpt-review" ]; then
    BRIDGE="$HOME/.config/opencode/chatgpt-bridge/bin/chatgpt-review"
  elif [ -x "$HOME/.gemini/chatgpt-bridge/bin/chatgpt-review" ]; then
    BRIDGE="$HOME/.gemini/chatgpt-bridge/bin/chatgpt-review"
  else
    echo "ERROR: chatgpt-review command not found." >&2
    exit 1
  fi
}

if [ "$#" -gt 0 ]; then
  echo "ERROR: merge-approved-pr accepts no arguments (no --admin, no bypass flags)." >&2
  exit 2
fi

branch="$(git branch --show-current)"
if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
  echo "ERROR: could not determine a current branch (detached HEAD?)." >&2
  exit 1
fi

candidates="$(
  gh pr list --state open --head "$branch" \
    --json number,isCrossRepository \
    --jq '[.[] | select(.isCrossRepository == false) | .number]'
)"
count="$(printf '%s' "$candidates" | jq 'length')"
if [ "$count" -ne 1 ]; then
  echo "ERROR: expected exactly one OPEN same-repo PR for branch '$branch'; found $count." >&2
  exit 1
fi
pr="$(printf '%s' "$candidates" | jq -r '.[0]')"

pr_data="$(gh pr view "$pr" --json state,mergeable,headRefOid,baseRefName --jq '.' 2>&1)"
state="$(printf '%s' "$pr_data" | jq -r '.state')"
mergeable="$(printf '%s' "$pr_data" | jq -r '.mergeable')"
head_oid="$(printf '%s' "$pr_data" | jq -r '.headRefOid')"
base="$(printf '%s' "$pr_data" | jq -r '.baseRefName')"

[ "$state" = "OPEN" ] || { echo "ERROR: PR #$pr is not OPEN (state=$state)." >&2; exit 1; }
[ "$mergeable" = "MERGEABLE" ] || { echo "ERROR: PR #$pr is not mergeable (mergeable=$mergeable)." >&2; exit 1; }

local_head="$(git rev-parse HEAD)"

# Verify recorded ChatGPT approval
approval="$("$BRIDGE" approval get 2>&1)"
approval_verdict="$(printf '%s' "$approval" | jq -r '.verdict // "none"' 2>/dev/null || echo none)"
approval_sha="$(printf '%s' "$approval" | jq -r '.headSha // ""' 2>/dev/null || echo "")"
approval_pr="$(printf '%s' "$approval" | jq -r '.pr // ""' 2>/dev/null || echo "")"

[ "$approval_verdict" = "approve" ] || { echo "ERROR: no recorded 'approve' verdict (verdict=$approval_verdict). Run chatgpt-review first." >&2; exit 1; }
if [ -z "$approval_sha" ] || [ "$approval_sha" != "$local_head" ]; then
  echo "ERROR: recorded approval headSha ('$approval_sha') does not match local HEAD ($local_head). Re-review this HEAD." >&2
  exit 1
fi
if [ -n "$approval_pr" ] && [ "$approval_pr" != "$pr" ]; then
  echo "ERROR: recorded approval is for PR #$approval_pr, but branch '$branch' resolves to PR #$pr." >&2
  exit 1
fi

# Verify status checks
if ! checks_out="$(gh pr checks "$pr" --json name,state 2>&1)"; then
  echo "ERROR: could not query status checks for PR #$pr. Aborting without merging." >&2
  echo "$checks_out" >&2
  exit 1
fi
non_success="$(printf '%s' "$checks_out" | jq -r '[.[] | select(.state != "SUCCESS") | .name] | .[]' 2>/dev/null)"
if [ -n "$non_success" ]; then
  echo "ERROR: non-SUCCESS checks on PR #$pr:" >&2
  printf '%s\n' "$non_success" >&2
  exit 1
fi

echo "All safety checks passed for PR #$pr (base=$base, head=$local_head). Merging..."
gh pr merge "$pr" --merge --match-head-commit "$local_head"
echo "Merged PR #$pr at commit $local_head."
