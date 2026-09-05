# AGENTS.md — Setup runbook for Antigravity Review Bridge

This repository installs a **ChatGPT Plus (web) & Google Gemini (web) review bridge** into Google Antigravity (AGY) so the agent can send summaries of completed tasks to ChatGPT / Gemini for independent review and receive machine-actionable verdicts — no manual copy-paste, no API quota consumed.

## TL;DR (Setup)

```bash
bash install.sh
# Pick ONE login style per bridge — manual (handles 2FA/CAPTCHA) or --auto from .env (no typing):
chatgpt-review login   # sign in to ChatGPT in the browser (1 time, handles 2FA/CAPTCHA)
# ...or:  fill ~/.gemini/chatgpt-bridge/.env (CHATGPT_EMAIL/CHATGPT_PASSWORD, chmod 600), then:
# chatgpt-review login --auto
chatgpt-review status  # verify "loggedIn": true (also reports envConfigured)

# Optional: Google Gemini second opinion
gemini-review login    # sign in with Google account (1 time)
# ...or:  fill ~/.gemini/gemini-bridge/.env (GEMINI_EMAIL/GEMINI_PASSWORD, chmod 600), then:
# gemini-review login --auto
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
bash -n bin/agy-work install.sh bin/autoreview bin/chatgpt-review bin/gemini-review templates/merge-approved-pr.sh
node --check bin/chatgpt-review.mjs bin/gemini-review.mjs bin/session-auth.mjs bin/bridge-env.mjs
bash tests/test.sh

chatgpt-review status
# Expect: {"profileExists":true,"cookiesExist":true,"loggedIn":true,"envConfigured":true/false}

gemini-review status
# Expect: {"profileExists":true,"cookiesExist":true,"loggedIn":true,"guestAvailable":false}

cd <any-repo> && chatgpt-review chats
# Expect: prints current repo+branch mapping without error
```

If `status` shows `loggedIn: false`, either run the matching `login --auto` (when its
`.env` holds `CHATGPT_EMAIL/CHATGPT_PASSWORD` or `GEMINI_EMAIL/GEMINI_PASSWORD`,
`chmod 600`, `status` reports `envConfigured:true`) or run the manual `login` and
ask the human to sign in in the browser window, then re-check. Manual login is
still required once when 2FA/CAPTCHA/"browser may not be secure" appears — the
saved profile is reused afterwards, and `ask` auto-retries `.env` login on expiry
(unless `--no-auto-login`). To switch ChatGPT account: `chatgpt-review login --switch` (keeps browser open, waits for token change; use `--wait=SECONDS` to keep open after new login). Gemini now distinguishes `loggedIn` vs `guestAvailable` via `session-auth.mjs` classifier (needs 3 stable checks).

See also `docs/TROUBLESHOOTING.md` and `docs/AUTO_LOGIN.md`.

## Rules

- Never commit `profile/`, `chats.json`, `projects.json`, `autoreview.json`, `.env`,
  `node_modules/`, `libs/`, or any file under
  `~/.gemini/{chatgpt,gemini}-bridge/profile/`.
- Never print session cookies or tokens.
- Keep the existing machine's local state (`chats.json`, `projects.json`,
  `profile/`) — `install.sh` only overwrites code/config, not runtime state.
- The bridges run **headful** by default (needed to pass Cloudflare / Google
  checks). On a headless server, use `xvfb-run` or a virtual display.
