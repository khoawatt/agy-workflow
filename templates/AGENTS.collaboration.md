## ChatGPT–Antigravity Collaboration Guidelines

GitHub is the communication protocol for implementation and review.

The linked GitHub Issue is the task and scope authority.

Antigravity is the implementation agent.

Antigravity must:
- Inspect repository and git state before making changes;
- Preserve uncommitted work;
- Follow the linked Issue and canonical project specs;
- Remain strictly inside approved scope;
- For UI/multimodal analysis, inspect screenshots and assets directly using vision capabilities;
- Run real verification tests before claiming completion;
- Self-review diffs before handing off;
- Hand off meaningful work through Pull Requests;
- Respond to actionable ChatGPT review feedback;
- Never merge by default without human authorization.

### ChatGPT Review Bridge (Independent Review)

Before finalizing work or opening/merging a Pull Request, trigger an external review through the ChatGPT bridge:

1. Produce the final task summary (Done / What changed / Verification).
2. Invoke `/chatgpt-review` (or the `chatgpt-review` skill).
3. The skill sends the summary in a workflow envelope to ChatGPT Plus (web) via the browser bridge and reads back a machine-actionable verdict (`approve`, `approve-with-changes`, `request-changes`, `reject`).
4. On `approve`, status advances to awaiting human merge.
5. On `request-changes`, fix issues and re-review.

### Secondary Opinion: Google Gemini Review

To obtain a cross-check / second opinion from Google Gemini:
- Invoke `/gemini-review` (or the `gemini-review` skill).
- The verdict is advisory and does not record an official approval state.

### Human Authority

The human maintainer retains final authority over:
- Merging PRs and deployments;
- Production and infrastructure changes;
- Architecture and scope changes;
- Adding/changing dependencies.

Merge is permitted via `.agents/scripts/merge-approved-pr.sh` once approved by ChatGPT and CI passes.
