# CTFd Configuration & API Quirks

## Email Configuration

- **Provider:** Gmail SMTP
- **SMTP Server:** `smtp.gmail.com`
- **Port:** `587`
- **TLS:** Enabled (STARTTLS)
- **Cấu hình trong CTFd:** Admin Panel → Config → Email

### Domain Allowlist (Whitelist)

Chỉ cho phép đăng ký từ email domain nội bộ:
- Domain: `tdtu.edu.vn`, `student.tdtu.edu.vn`

> **Quan trọng:** Danh sách domain phải được nhập trên **một dòng duy nhất**, cách nhau bằng dấu phẩy:
> ```
> student.tdtu.edu.vn,tdtu.edu.vn
> ```
> Nếu để mỗi domain trên một dòng, parser của CTFd sẽ bị lỗi và không whitelist được.

## File Uploads – Lỗi Permission

CTFd container chạy với user `ctfd` **(UID 1001)**. Thư mục bind-mount `/opt/ctfd/uploads` → `/var/uploads` phải thuộc UID 1001.

**Triệu chứng:** Upload file trong Admin Panel bị lỗi `PermissionError: [Errno 13] Permission denied`.

**Giải pháp:**
```bash
sudo chown -R 1001:1001 /opt/ctfd/uploads
sudo chmod -R 755 /opt/ctfd/uploads
```

## API Quirks

### Tạo Team Invite Link

Endpoint đúng để generate invite token:

```http
POST /api/v1/teams/me/members
Content-Type: application/json
Authorization: Token <your_token>

{}
```

> **Chú ý:**
> - Endpoint `/api/v1/teams/me/tokens` sẽ trả về **404** — đây là endpoint sai.
> - Chỉ **Team Captain** mới có thể generate invite code, các thành viên thường sẽ nhận **403**.

### Email Resend Confirmation

- Trong `confirm.html`, nút "Gửi lại email" gọi `POST /confirm`.
- Ngay cả khi response là `200 OK`, email vẫn có thể vào **Spam/Junk folder**, đặc biệt với domain `.edu.vn`.
- Cần hướng dẫn user kiểm tra thư mục Spam.

### Redis Cache

CTFd cache template HTML trong Redis. Sau mỗi lần cập nhật template, **bắt buộc** flush cache:

```bash
sudo docker exec ctfd_cache_1 redis-cli FLUSHALL
```

## Cấu hình CTFd cần thiết (Admin Panel)

| Mục | Giá trị |
|---|---|
| **CTF Name** | CyberKnight Weekly Game 2026 |
| **User Mode** | Teams |
| **Registration** | Enabled (chỉ domain whitelist) |
| **Team Size** | Theo quy định (ví dụ: 4) |
| **Theme** | ctfd-theme-neubrutalism |
| **Reverse Proxy** | Enabled (CTFd nhận traffic qua Nginx) |
| **Domain Allowlist** | `student.tdtu.edu.vn,tdtu.edu.vn` |
