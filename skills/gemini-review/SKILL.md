---
name: gemini-review
description: Workflow-aware independent reviewer (second opinion). Sends an agent's completed task result (summary text, not raw diffs) to Google Gemini (web) through a browser bridge, wrapped in structured workflow context, and returns a machine-actionable verdict. Use when the user asks for a Gemini review, "gửi cho gemini review", "hỏi gemini", or a cross-check besides ChatGPT.
---

# gemini-review

Send a completed task's **final result summary** to Google Gemini
(gemini.google.com/app) through a Playwright browser bridge, wrapped in a structured
workflow envelope, and read back a machine-actionable verdict.
The user does **not** copy-paste anything.

## Role in the workflow

`gemini-review` is a **second-opinion / cross-check reviewer**. The
authoritative approval loop stays with `chatgpt-review` (its `approval set`
state feeds `merge-approved-pr.sh`). Gemini's verdict is advisory: report it,
compare it with ChatGPT's when both exist, but never record it as workflow
approval state.

## Steps

1. Check the bridge is ready:
   `gemini-review status`
   (if `loggedIn` is `false`, report that the user must run `gemini-review login` once; do not review.)

2. Collect lightweight repo context:
   - `git rev-parse --abbrev-ref HEAD` (branch)
   - `git rev-parse HEAD` (head SHA)
   - `git status --short` (working-tree state, one glance)

3. Determine `MODE` from context:
   - `implementation-review` | `bugfix-review` | `followup-review` | `pre-pr-review` | `pr-review` | `planning-review` | `continuation-review`

4. Compose the review prompt as a single string using this structured envelope:

   ```text
   MODE: <mode>
   GOAL: <overall task/issue goal, 1-2 sentences>
   CURRENT_STAGE: <IMPLEMENTING | IMPLEMENTATION_COMPLETE | REVIEW | FIXES | APPROVED>
   TASK_SUMMARY: <one line>
   RESULT_TEXT: <the implementing agent's final Done / What changed / Verification text verbatim>
   REQUESTED_DECISION: <what Gemini should determine>
   NEXT_ACTION_IF_APPROVED: <what happens next>
   NEXT_ACTION_IF_CHANGES_REQUESTED: <what the agent does next>
   REPO: <repo name>
   BRANCH: <branch>
   HEAD_SHA: <sha>
   AUTHORITY:
   - Gemini: independent second-opinion review; approve/request-changes; recommend next workflow action.
   - Antigravity Agent: implementation, fixes, tests, commits, pushes.
   - Human maintainer: merge/deploy authority only.

   Respond in this exact machine-actionable format:

   VERDICT: approve | approve-with-changes | request-changes | reject
   NEXT_ACTION: <single explicit next workflow action>
   ISSUES: <numbered actionable issues, or "none">
   SUGGESTIONS: <optional>
   ```

5. Send it by feeding the prompt to the bridge on stdin via a **quoted heredoc**:

   ```bash
   gemini-review ask <<'GEMINI_REVIEW_PROMPT_EOF'
   <the full envelope from step 4, verbatim>
   GEMINI_REVIEW_PROMPT_EOF
   ```

6. Parse the verdict from Gemini's reply. Do NOT record any approval state —
   just report it.

7. Return Gemini's reply verbatim, then a 2-3 line summary: verdict, next action,
   and whether it agrees with any prior ChatGPT verdict if one is known.

## Rules

- Never treat "approve" as permission to merge — report it as "awaiting human merge".
- If the bridge throws an error, surface the exact error; do not claim a review succeeded.
- Keep the envelope small — no full conversation dumps, no raw diffs.
