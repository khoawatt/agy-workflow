# AGENTS.md — Setup runbook for Antigravity Review Bridge

This repository installs a **ChatGPT Plus (web) & Google Gemini (web) review bridge** into Google Antigravity (AGY) so the agent can send summaries of completed tasks to ChatGPT / Gemini for independent review and receive machine-actionable verdicts — no manual copy-paste, no API quota consumed.

## TL;DR (Setup)

```bash
bash install.sh
chatgpt-review login   # sign in to ChatGPT in the browser (1 time)
chatgpt-review status  # verify "loggedIn": true

# Optional: Google Gemini second opinion
gemini-review login    # sign in with Google account (1 time)
gemini-review status   # verify "loggedIn": true
```

## What `install.sh` does

1. Copies skills into `~/.gemini/config/skills/`:
   - `chatgpt-review` — independent reviewer via ChatGPT Plus
   - `gemini-review` — second-opinion reviewer via Google Gemini
   - `autoreview` — toggle auto-review on/off/status
   - `chatgpt-project` — manage ChatGPT Project mappings
   - `chatgpt-new` / `gemini-new` — reset conversation threads
2. Installs bridge scripts and manifests to `~/.gemini/chatgpt-bridge/` and `~/.gemini/gemini-bridge/`.
3. Creates symlinks in `~/.local/bin/` (`chatgpt-review`, `gemini-review`, `autoreview`, `agy-work`).
4. Reuses existing Playwright Chromium browser profiles if present.
5. Installs Playwright dependencies if needed.

## Verification checklist

```bash
chatgpt-review status
# Expect: {"profileExists":true,"cookiesExist":true,"loggedIn":true}

gemini-review status
# Expect: {"profileExists":true,"cookiesExist":true,"loggedIn":true}

cd <any-repo> && chatgpt-review chats
# Expect: prints current repo+branch mapping without error
```
