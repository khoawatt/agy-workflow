# Antigravity Workflow (agy-workflow)

Bộ quy trình chuẩn cho **Google Antigravity (AGY) ↔ ChatGPT Plus / Google Gemini Web** collaboration:

1. **Review bridge (ChatGPT)**: Gửi **kết quả tổng kết task** (text summary "Done / What changed / Verification") lên **ChatGPT Plus (web)** như một **reviewer độc lập, workflow-aware**, nhận về **verdict machine-actionable** (`approve`, `approve-with-changes`, `request-changes`, `reject`).
2. **Gemini bridge (Google Gemini Web)**: Gửi summary lên **Google Gemini (web)** đóng vai trò reviewer thứ hai để cross-check (`gemini-review`), không ghi approval state chính thức.
3. **Chống vòng lặp review (Anti-review loop)**: Lưu trạng thái `approve` + HEAD SHA; nếu state chưa đổi thì không review lại, chỉ báo "awaiting human merge".
4. **Hooks & Auto-Review**: Hỗ trợ hook `PreInvocation` tự động nhắc nhở agent review kết quả sau mỗi task thay đổi code (`autoreview on/off`).
5. **Policy & merge wrapper**: Script `merge-approved-pr.sh` đảm bảo an toàn tuyệt đối khi merge PR (chỉ merge khi có verdict `approve` trùng commit HEAD và CI green).
6. **`agy-work`**: Tmux launcher chạy song song nhiều repo trong Antigravity CLI (2 panes side-by-side).

---

## Cài đặt nhanh

```bash
cd /home/audition/projects/personal/agy-workflow
bash install.sh
chatgpt-review login     # Đăng nhập ChatGPT (1 lần duy nhất trên trình duyệt)
gemini-review login      # (Tùy chọn) Đăng nhập Google Gemini
chatgpt-review status    # Kiểm tra trạng thái đăng nhập
```

Áp dụng workflow vào repo dự án bất kỳ:

```bash
bash install-project.sh /path/to/your/project-repo
```

Khởi chạy song song 2 repo bằng tmux launcher:

```bash
agy-work
```

---

## Tính năng & Lệnh điều khiển

| Lệnh / Skill | Mô tả |
|---|---|
| `/chatgpt-review` | Gửi summary task lên ChatGPT Plus duyệt độc lập |
| `/gemini-review` | Gửi summary task lên Google Gemini để lấy ý kiến thứ hai (cross-check) |
| `sources` / `chatgpt-review sources` | Đồng bộ hybrid code snapshot (.zip) lên ChatGPT Project Sources |
| `/autoreview on\|off\|status` | Bật / tắt chế độ tự động review sau mỗi task code |
| `/chatgpt-project` | Quản lý ChatGPT Project theo repository (`list`, `create`, `attach`, `detach`) |
| `/chatgpt-new` | Reset thread ChatGPT hiện tại của branch để bắt đầu hội thoại mới |
| `/gemini-new` | Reset thread Gemini hiện tại của branch |
| `agy-work` | Tmux workspace launcher hỗ trợ N repos theo `config/projects.conf` |
| `merge-approved-pr.sh` | Merge an toàn Pull Request đã được ChatGPT review approve và CI pass |

---

## Tài liệu chi tiết (`docs/`)

- [Kiến trúc hệ thống (Architecture)](file:///home/audition/projects/personal/agy-workflow/docs/ARCHITECTURE.md)
- [Quy trình Review (Workflow)](file:///home/audition/projects/personal/agy-workflow/docs/WORKFLOW.md)
- [Thiết lập & Cài đặt (Setup Guide)](file:///home/audition/projects/personal/agy-workflow/docs/SETUP.md)
- [Cấu hình chi tiết (Configuration)](file:///home/audition/projects/personal/agy-workflow/docs/CONFIGURATION.md)
- [Tài liệu Gemini Web Scraper](file:///home/audition/projects/personal/agy-workflow/docs/GEMINI_WEB.md)
- [Xử lý sự cố (Troubleshooting)](file:///home/audition/projects/personal/agy-workflow/docs/TROUBLESHOOTING.md)

---

## Đóng góp (Contributing)

Mọi đóng góp nhằm hoàn thiện hoặc sửa lỗi đều được hoan nghênh. Vui lòng tham khảo [CONTRIBUTING.md](file:///home/audition/projects/personal/agy-workflow/CONTRIBUTING.md) trước khi tạo pull request.

---

## Tác giả & Người duy trì (Authors & Contributors)

* **Quách Võ Anh Khoa** ([@khoawatt](https://github.com/khoawatt)) - *Author & Maintainer*

---

## Giấy phép (License)

Dự án này được phân phối dưới giấy phép **MIT License**. Xem chi tiết tại [LICENSE](file:///home/audition/projects/personal/agy-workflow/LICENSE).

