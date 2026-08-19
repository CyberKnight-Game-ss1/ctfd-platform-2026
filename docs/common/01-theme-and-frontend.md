# Theme và Frontend Customizations

## Theme đang dùng

Platform dùng theme tùy chỉnh **`ctfd-theme-neubrutalism`** đặt tại `themes/ctfd-theme-neubrutalism/`.

## Alpine.js vs Vanilla JS

### Vấn đề

CTFd mặc định dùng **Alpine.js** (`x-data`, `@click`, `x-bind`) cho các tương tác UI. Tuy nhiên, khi kết hợp với các script tùy chỉnh và cách CTFd load scripts, Alpine.js hay bị conflict dẫn đến:
- Nút bấm không phản hồi.
- Form không submit được.
- Directive Alpine không được evaluate.

### Giải pháp

Với các **user flow quan trọng**, ta loại bỏ Alpine.js directives và thay bằng **Vanilla JavaScript** kết hợp **Bootstrap 5 Modals**.

### Các template đã được chỉnh sửa

| Template | Thay đổi |
|---|---|
| `templates/teams/private.html` | Thay Alpine invite modal → Vanilla JS + `fetch()` API tới `/api/v1/teams/me/members` |
| `templates/settings.html` | Rewrite profile update form bằng Vanilla JS + `fetch()` |
| `templates/confirm.html` | Full-screen blocking modal bắt buộc verify email |
| `templates/components/snackbar.html` | Loại bỏ Alpine dismissal logic |

## Rebranding

Tất cả nhãn hiệu của CTFd gốc đã được thay thế để platform trông hoàn toàn nội bộ:

- **Navbar**: "CTFd" → "CyberKnight Core Team"
- **Footer**: Removed third-party credits → "Internal Web Exploit CTF"
- **Login page**: Tùy chỉnh background, logo `static/img/logo.png`

## Build theme (nếu cần chỉnh sửa SCSS/JS)

```bash
cd themes/ctfd-theme-neubrutalism

# Cài dependencies
npm install

# Build production assets
npm run build

# Watch mode cho development
npm run dev
```

Sau khi build, static assets được tạo vào `static/assets/`. Commit cả thư mục `static/` vào git.

## Deploy theme lên server

### GCP

```bash
gcloud compute scp \
  "themes/ctfd-theme-neubrutalism/templates/login.html" \
  ubuntu@ctf-vm1-web:/home/ubuntu/ \
  --tunnel-through-iap

gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap --command="
  sudo cp /home/ubuntu/login.html \
    /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/login.html &&
  sudo docker exec ctfd_cache_1 redis-cli FLUSHALL
"
```

### AWS

```bash
VM1_ID=$(cd terraform/aws && terraform output -raw vm1_instance_id)

# Copy file qua SCP + SSM proxy
scp -o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region ap-southeast-1" \
  themes/ctfd-theme-neubrutalism/templates/login.html \
  ubuntu@$VM1_ID:/home/ubuntu/

# Copy vào Docker volume và flush cache
aws ssm send-command \
  --instance-ids $VM1_ID \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":[
    "sudo cp /home/ubuntu/login.html /opt/ctfd/themes/ctfd-theme-neubrutalism/templates/login.html",
    "sudo docker exec ctfd_cache_1 redis-cli FLUSHALL"
  ]}' \
  --region ap-southeast-1
```

> **Quan trọng:** Luôn `FLUSHALL` Redis cache sau khi sửa template HTML để CTFd load bản mới ngay lập tức.
