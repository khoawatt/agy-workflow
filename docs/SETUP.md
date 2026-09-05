# Setup Guide (new machine / team onboarding)

One-time setup to get the full Antigravity (AGY) ↔ ChatGPT workflow running, including the
`agy-work` tmux launcher that runs two (or more) repos side by side.

---

## 1. Install the workflow globally

```bash
git clone https://github.com/khoawatt/agy-workflow.git
cd agy-workflow
bash install.sh
```

`install.sh` copies skills into `~/.gemini/config/skills/`, installs
`npm` deps + Playwright Chromium (shared by the ChatGPT and Gemini bridges),
installs Chromium system libraries (sudo if available, else user-space `.deb`
extraction into `libs/`), and sets up `~/.gemini/config/projects.conf` for the
`agy-work` launcher (see `docs/CONFIGURATION.md`).

Then pick ONE login style per bridge (see `docs/AUTO_LOGIN.md`):

```bash
# Manual (handles 2FA/CAPTCHA) — sign in once in the opened browser:
~/.gemini/chatgpt-bridge/bin/chatgpt-review login    # sign in to ChatGPT (once)
~/.gemini/chatgpt-bridge/bin/chatgpt-review status   # → "loggedIn": true
# To switch account: chatgpt-review login --switch  (or --wait=30)
~/.gemini/gemini-bridge/bin/gemini-review login      # optional: Google account for Gemini
~/.gemini/gemini-bridge/bin/gemini-review status     # → "loggedIn": true, guestAvailable:false

# ...or fully automatic from .env (no manual typing):
# fill ~/.gemini/chatgpt-bridge/.env (CHATGPT_EMAIL/CHATGPT_PASSWORD, chmod 600)
~/.gemini/chatgpt-bridge/bin/chatgpt-review login --auto
# fill ~/.gemini/gemini-bridge/.env (GEMINI_EMAIL/GEMINI_PASSWORD, chmod 600)
~/.gemini/gemini-bridge/bin/gemini-review login --auto
# After that, `ask` auto-retries .env login on session expiry (disable with --no-auto-login).
```

If `gemini-review status` shows `guestAvailable:true` (composer visible but no identity), sign in fully and wait for 3 stable checks (5s settled). See `docs/GEMINI_WEB.md`.

Restart agy to load the new agent/skill/commands.

## 2. Install per repository

```bash
bash install-project.sh /path/to/your/repo
```

This copies the canonical policy (`opencode.jsonc`), the collaboration section
(`AGENTS.collaboration.md`), and the `.opencode/` resources (agents, commands,
scripts, skills) into the target repo. It **merges** — it never overwrites an
existing file; it copies only files that don't already exist and reports anything
it skipped.

## 3. The `agy-work` tmux launcher

`bin/agy-work` opens a tmux session `agy-work` with one pane per
project in `~/.gemini/config/projects.conf` (fallback to 2 panes `Feaon` + `qvak` if config missing), each running Antigravity (AGY) in its own repository, passing the project path
explicitly so each pane is bound to the correct workspace.

Config detail: see `docs/CONFIGURATION.md` — `name|git_url|checkout_path`, 2 projects → `even-horizontal` 50-50, else `tiled`.

### Install

```bash
mkdir -p ~/.local/bin
cp bin/agy-work ~/.local/bin/agy-work
chmod +x ~/.local/bin/agy-work
# ensure ~/.local/bin is on PATH
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc ;; esac
```

### Usage

```bash
agy-work            # create/attach the N-pane session (reads projects.conf)
agy-work --status   # show configured projects + session state (running/stopped)
agy-work --reset    # rebuild the session (e.g. after editing projects.conf)
agy-work --help     # show help
# Config/session overrides:
AGY_WORK_CONFIG=/path/to/team.conf AGY_WORK_SESSION=team-work agy-work
```

Detach with `Ctrl+b d` (keeps both Antigravity (AGY) processes running); re-run
`agy-work` to re-attach. Switch panes with `Ctrl+b ←/→`, zoom with `Ctrl+b z`.

### `--auto` mode

The launcher defaults to **`--auto`** (`AGY_WORK_AUTO=1`), which auto-approves
`ask`-tier permissions for this trusted local workspace.

| Want | Command |
|---|---|
| Auto-approve `ask` (default) | `agy-work` |
| Ask before mutating ops | `AGY_WORK_AUTO=0 agy-work --reset` |

`AGY_WORK_AUTO` only affects new Antigravity (AGY) processes — use `--reset` to apply
a mode change to an existing session.

> Note the tension: `--auto` auto-approves **all** `ask`-tier ops (including
> destructive ops and `gh pr merge` raw). If you want a human gate on those, run
> with `AGY_WORK_AUTO=0`.

## 4. Verify

```bash
bash -n bin/agy-work install.sh install-project.sh bin/autoreview bin/chatgpt-review bin/gemini-review templates/merge-approved-pr.sh
node --check bin/chatgpt-review.mjs bin/gemini-review.mjs bin/session-auth.mjs bin/bridge-env.mjs
bash tests/test.sh

~/.gemini/chatgpt-bridge/bin/chatgpt-review status   # loggedIn: true
cd <repo> && ~/.gemini/chatgpt-bridge/bin/chatgpt-review chats  # no crash (identity:branch)
~/.gemini/chatgpt-bridge/bin/chatgpt-review project list        # projects (may be empty)
~/.gemini/gemini-bridge/bin/gemini-review status     # loggedIn: true, guestAvailable:false (if set up)
cd <repo> && ~/.gemini/gemini-bridge/bin/gemini-review chats    # no crash
agy-work --status                                        # shows N projects + State
tmux ls                                                        # agy-work session
tmux list-panes -t agy-work -F '#{pane_id} #{pane_current_path} #{pane_current_command}'
```

Expected: N panes (2 → `even-horizontal`, else `tiled`), one per non-comment line in `~/.gemini/config/projects.conf` (fallback 2).

## 5. Troubleshooting

| Symptom | Fix |
|---|---|
| `Chromium not found` | `npm exec --prefix ~/.gemini/chatgpt-bridge playwright install chromium` |
| `libnspr4.so ... not found` | re-run `bash install.sh --deps` |
| `loggedIn: false` (ChatGPT) | run `.../chatgpt-review login` and wait for "LOGIN OK" |
| `loggedIn: false` (Gemini) | run `~/.gemini/gemini-bridge/bin/gemini-review login`, sign in with Google, complete any consent screen |
| Gemini asks "unusual traffic" | solve it manually in the login window; cannot be automated |
| `sessions should be nested with care` | the script handles nested tmux via `switch-client`; check `command -v agy-work` |
| session has wrong/one pane | `agy-work --reset` |
| Antigravity (AGY) asks `external_directory` | ensure each pane was launched with the explicit repo path (the script does this) |
| last resort | `tmux kill-server` (closes ALL tmux sessions) then `agy-work` |
