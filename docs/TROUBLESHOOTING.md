# Troubleshooting và rollback (agy-workflow)

| Hiện tượng | Cách xử lý |
|---|---|
| `Chromium not found` | `npm exec --prefix ~/.gemini/chatgpt-bridge playwright install chromium` (hoặc `bash install.sh --deps`) |
| `libnspr4.so` / `libnss3.so` / `libasound.so` not found | re-run `bash install.sh --deps` — installer thử `sudo apt-get install` nếu có passwordless sudo, else extract user-space `.deb` vào `libs/` |
| `chatgpt-review` báo `loggedIn: false` | chạy `~/.gemini/chatgpt-bridge/bin/chatgpt-review login` trong desktop có display, đợi `LOGIN OK` — hoặc cấu hình `.env` rồi `login --auto` (xem `docs/AUTO_LOGIN.md`) |
| `login --auto` báo thiếu credentials | điền `CHATGPT_EMAIL/CHATGPT_PASSWORD` (hoặc `GEMINI_EMAIL/GEMINI_PASSWORD`) vào bridge `.env`, `chmod 600`, chạy lại; shell env thắng file |
| `login --auto` báo sai password / không tìm thấy account | kiểm tra lại email/password trong `.env` (log chỉ hiện email mask); đổi pass thì cập nhật `.env` |
| `login --auto` báo 2FA/CAPTCHA/`browser may not be secure` | auto không qua được — chạy `login` thủ công 1 lần để lưu `profile/`, các lần sau tái dùng; `ask` sẽ tự retry `.env` khi hết session |
| `.env` báo `insecure permissions` | `chmod 600 ~/.gemini/{chatgpt,gemini}-bridge/.env` |
| `chatgpt-review login` muốn đổi account | `chatgpt-review login --switch` (giữ browser mở, đợi token đổi; thêm `--wait=30` để giữ mở 30s sau login mới) |
| `chatgpt-review login` treo sau khi đóng window | đã fix `browserClosed` detection — đóng window sẽ báo `LOGIN OK (browser closed)` nếu có session, else `No session cookie`; nếu vẫn treo, `cat ~/.gemini/chatgpt-bridge/.lock` và check PID |
| Bridge không tìm thấy prompt input | ChatGPT Web có thể đã đổi UI; cập nhật bridge, không coi lần review là thành công. Thử `chatgpt-review status` headful để debug `url/title/loggedIn` |
| Codex/OpenCode không tự review | kiểm tra `~/.gemini/agy.jsonc` có plugin `superpowers` không, rồi restart agy |
| Bridge đang bị lock | chờ lần review hiện tại xong; lock của PID đã chết sẽ tự được dọn (`kill(pid,0)` + `Atomics.wait`). Kiểm tra `cat ~/.gemini/chatgpt-bridge/.lock` |
| Auto-review đổi trạng thái nhưng session cũ không làm theo | plugin `chatgpt-autoreview.ts` chỉ inject khi `autoreview.json:enabled=true`; restart agy session đó |
| Approval không khớp HEAD/PR/repo | `chatgpt-review approval get` so sánh `head_sha` 40-char + `pr` + repo case-insensitive; `approval clear` rồi review lại exact HEAD |
| ChatGPT Project command lỗi / `could not fetch projects` | đã fix direct `fetch` + 3 lần retry (in-flight → goto → reload); nếu vẫn lỗi, dùng plain `ask --no-project` |
| Sidebar collapsed làm `create project` bấm hụt | đã fix auto-expand `Open sidebar` + `data-state` check (dbg3 vs dbg4) |
| `gemini-review` báo `loggedIn: false` | `~/.gemini/gemini-bridge/bin/gemini-review login` trong môi trường có display, hoàn thành consent screen |
| `gemini-review` báo `guestAvailable:true` | Gemini cho guest gửi prompt nhưng chưa có account identity thật — đăng nhập Google account đầy đủ, đợi 3 stable checks (5s settled) |
| Gemini không tìm thấy prompt/send/response | Gemini Web đã đổi UI; không coi scrape thành công và cập nhật selector (`PROMPT_SELECTORS`/`SEND_SELECTORS`/`REPLY_SELECTORS`) |
| `agy-work: command not found` | thêm `~/.local/bin` vào `PATH` |
| `agy-work` báo `Project ... is missing` | `bash install.sh` để clone, hoặc sửa checkout path trong `~/.gemini/projects.conf` |
| Session không khớp config | `agy-work --reset` |
| Đang ở trong tmux `switch-client` | script đã xử lý nested tmux via `switch-client`; check `command -v agy-work` |
| last resort | `tmux kill-session -t agy-work` rồi `agy-work`; không dùng `tmux kill-server` (đóng cả session không liên quan) |

## Kiểm tra session

```bash
agy-work --status
tmux ls
tmux list-panes -t agy-work -F '#{pane_id}|#{pane_current_path}|#{pane_current_command}'
~/.gemini/chatgpt-bridge/bin/chatgpt-review status
~/.gemini/gemini-bridge/bin/gemini-review status
```

## Rollback local

Detach trước nếu đang ở trong session:

```bash
tmux kill-session -t agy-work       # chỉ khi muốn dừng các OpenCode process trong workspace
rm ~/.local/bin/agy-work
rm ~/.local/bin/chatgpt-review ~/.local/bin/gemini-review
```

Config local có thể giữ để cài lại. Nếu thật sự không cần nữa, backup rồi xóa `~/.gemini/chatgpt-bridge/` / `gemini-bridge/` riêng. Không dùng `tmux kill-server`.

Rollback riêng ChatGPT/Gemini được mô tả trong `docs/CHATGPT_WEB.md` / `docs/GEMINI_WEB.md`; việc xóa profile browser sẽ đăng xuất bridge và không ảnh hưởng agy auth.
