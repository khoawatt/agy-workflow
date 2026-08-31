---
name: chatgpt-review
description: Workflow-aware independent reviewer. Sends an agent's completed task result (summary text, not raw diffs) to ChatGPT Plus (web) through a browser bridge, wrapped in structured workflow context, and returns a machine-actionable verdict that advances the workflow. Use when the user asks for an external/ChatGPT review, or when auto-review runs after a task completes.
---

# chatgpt-review

Send a completed task's **final result summary** to ChatGPT Plus (web) through a
Playwright browser bridge, wrapped in a structured workflow envelope, and read back
a machine-actionable verdict. The user does **not** copy-paste anything.

## What gets reviewed

The implementing agent's own result text — e.g. "Done / What changed / Verification".
**Never** send raw git diffs through the bridge. ChatGPT is instructed to inspect
GitHub state itself when it needs deeper verification.

## Pre-check: avoid redundant reviews

Before sending, get the saved approval state for the current repo+branch:

```bash
chatgpt-review approval get
```

Then get the current HEAD SHA:

```bash
git rev-parse HEAD
```

If `approval get` returns `{ "verdict": "approve", "headSha": <sha> }` and the
current HEAD SHA equals that stored `headSha` and nothing else materially changed,
do NOT send another review. Report:

```text
ChatGPT already approved HEAD <sha>. Status: awaiting human merge.
```

If the approval verdict is `request-changes`/`reject`, or the HEAD SHA differs,
or there is no saved approval, proceed with a fresh review.

## Steps (when a review is warranted)

1. Check the bridge is ready:
   `chatgpt-review status`
   (if `loggedIn` is `false`, report that the user must run `chatgpt-review login` once; do not review.)

2. Collect lightweight GitHub context (only what is cheap and available):
   - `git rev-parse --abbrev-ref HEAD` (branch)
   - `git rev-parse HEAD` (head SHA)
   - `git status --short` (working-tree state, one glance)
   - If a PR number is known/mentioned, `gh pr view <n> --json number,state,headRefName,baseRefName,statusCheckRollup` (best-effort; ignore failures).

3. Determine `MODE` from context (pick the closest, do not invent new ones):
   - `implementation-review` — a coding task just completed
   - `bugfix-review` — a bug fix
   - `followup-review` — re-review after previously requested changes
   - `pre-pr-review` — reviewing work about to become a PR
   - `pr-review` — reviewing an existing PR
   - `planning-review` — reviewing a plan/spec
   - `continuation-review` — a handoff/continuation of longer work

4. Compose the review prompt as a single string using this structured envelope
   (keep RESULT_TEXT = the caller's summary verbatim, no diff):

   ```text
   MODE: <mode>
   GOAL: <overall task/issue goal, 1-2 sentences>
   CURRENT_STAGE: <IMPLEMENTING | IMPLEMENTATION_COMPLETE | CHATGPT_REVIEW | FIXES | APPROVED>
   TASK_SUMMARY: <one line>
   RESULT_TEXT: <the implementing agent's final Done / What changed / Verification text verbatim>
   REQUESTED_DECISION: <what ChatGPT should determine>
   NEXT_ACTION_IF_APPROVED: <what happens next>
   NEXT_ACTION_IF_CHANGES_REQUESTED: <what the agent does next>
   REPO: <repo name>
   BRANCH: <branch>
   HEAD_SHA: <sha>
   PR: <pr number or none>
   BASE: <base branch if known>
   AUTHORITY:
   - ChatGPT: independent review; inspect GitHub/repo state when available; approve/request-changes; recommend next workflow action.
   - Antigravity Agent: implementation, fixes, tests, commits, pushes, issue/PR updates.
   - Human maintainer: merge/deploy authority only.

   Please inspect GitHub state where useful (PR state, HEAD SHA, CI status, diff)
   to verify the summary's claims. Do not require the raw diff to be pasted here.

   Respond in this exact machine-actionable format:

   VERDICT: approve | approve-with-changes | request-changes | reject
   NEXT_ACTION: <single explicit next workflow action>
   ISSUES: <numbered actionable issues, or "none">
   SUGGESTIONS: <optional>
   ```

   Verdict semantics:
   - `approve` = no blocking work remains;
   - `approve-with-changes` = only non-blocking cleanup (state whether another review is needed);
   - `request-changes` = agent must fix then re-review;
   - `reject` = replan required.

5. Send it by feeding the prompt to the bridge on stdin via a **quoted heredoc**:

   ```bash
   chatgpt-review ask <<'CHATGPT_REVIEW_PROMPT_EOF'
   <the full envelope from step 4, verbatim>
   CHATGPT_REVIEW_PROMPT_EOF
   ```

   The bridge reads stdin and prints ChatGPT's reply to stdout.

6. Parse the verdict from ChatGPT's reply, then record it:

   ```bash
   chatgpt-review approval set <verdict> <headSha> <pr-or-none>
   ```

   Only record `approve` / `approve-with-changes` / `request-changes` / `reject`.

7. Return ChatGPT's reply verbatim, then a 2-3 line summary: verdict, next action,
   and whether the workflow should advance or loop.

## Rules

- Never treat "approve" as permission to merge — report it as "awaiting human merge".
- If the bridge throws an error, surface the exact error; do not claim a review succeeded.
- Do not self-declare approval; ChatGPT decides.
- Keep the envelope small — no full conversation dumps, no raw diffs.
