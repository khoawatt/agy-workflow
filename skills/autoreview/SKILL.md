---
name: autoreview
description: Manage ChatGPT auto-review mode (on, off, status). When enabled, the agent automatically sends task results to ChatGPT for review after completing tasks that modify code.
---

# Auto-Review Management

Manage ChatGPT auto-review mode for Antigravity:

## Commands

Run the helper script via command:

```bash
autoreview on
autoreview off
autoreview status
```

Report the status to the user.
- When `on`: Inform the user that after each code implementation task, the agent will prepare a result summary and invoke the `chatgpt-review` skill.
- When `off`: Inform the user reviews are manual only (`/chatgpt-review`).
