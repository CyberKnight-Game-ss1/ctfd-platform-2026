# CLAUDE.md — CyberKnight CTFd Platform 2026

> Ngữ cảnh mặc định cho AI agent (Claude Code / Cline). Đọc kỹ trước khi thao tác.
> Tài liệu chi tiết: `.claude/README.md` · Kiến trúc AWS: `.claude/architecture/README.md`

## 1. Dự án là gì

**CyberKnight Weekly Game 2026** — nền tảng CTF nội bộ (TDTU), self-hosted **CTFd**,
triển khai qua IaC trên **AWS** (mục tiêu chính) hoặc GCP. Domain: `cyberknightgame.site`,
Cloudflare đứng trước, region AWS `ap-southeast-1` (Singapore).

## 2. Bản đồ thư mục

```
terraform/aws/     IaC: VPC, EC2 (VM1/VM2), RDS PostgreSQL 15, S3, SSM, EventBridge
terraform/gcp/     Bản GCP song song (tham khảo)
ansible/aws/       vm1_web.yml — CTFd + Redis + Nginx + FRPS + CloudWatch Agent
ansible/common/    vm2_challenge.yml (Docker, socket-proxy, tcpdump, K3s) + mtls_setup.yml
challenges/k8s/    network_policy.yaml, nsjail_pod.yaml — sandbox challenge
themes/            ctfd-theme-neubrutalism (Vite + SCSS + Vanilla JS)
scripts/           deploy_vm1.sh, deploy_vm2.sh, setup_ssl.sh, mtls_certs/ (KHÔNG commit)
docs/aws|gcp|common/  Tài liệu vận hành gốc
.claude/           Skills, commands, hooks, agents, kiến trúc cho AI agent
```

## 3. Luật bất di bất dịch (vi phạm = lỗi nghiêm trọng)

1. **Region luôn là `ap-southeast-1`.** Mọi lệnh `aws` phải có `--region ap-southeast-1` hoặc rely vào `AWS_DEFAULT_REGION` đã set trong `.claude/settings.json`.
2. **KHÔNG BAO GIỜ đọc/commit/print** (hook sẽ chặn):
   - `terraform.tfstate*`, `*.tfvars`, `terraform/.terraform/`
   - `scripts/mtls_certs/` (CA + private keys), `*.pem`, `*.key`
   - `ansible/*/inventory.ini` (chỉ `.example` được commit)
   - `ctfd_config.txt`, `remote_docker-compose.yml` (export cục bộ)
   - Password DB, SECRET_KEY, FRP token, AWS keys.
3. **Secrets chỉ tồn tại ở**: `terraform.tfvars` (local) và SSM Parameter Store `/ctfd/database-url` (SecureString). Không đặt secret vào `.env`, docs, log, code.
4. **Chặn phá hủy**: `terraform destroy`, `aws ec2 terminate-instances`, `aws rds delete-db-instance`, `s3 rb`, `DROP TABLE/DATABASE` — hook `.claude/hooks/guard_dangerous_ops.py` chặn ở PreToolUse. Nếu user yêu cầu thật sự, hãy giải thích rủi ro + yêu cầu user tự chạy trong terminal.
5. **SSH chỉ qua SSM Session Manager** (`aws ssm start-session --target <instance-id>`), không mở port 22, không SSH trực tiếp bằng IP.
6. `db.t3.micro` + `skip_final_snapshot=true` + `deletion_protection=false` chỉ dùng cho **luyện tập**; trước thi đấu thật phải flip: `deletion_protection=true`, `skip_final_snapshot=false`, RDS lên `db.t3.medium` (xem `.claude/architecture/07-cost.md`).

## 4. Lệnh triển khai chuẩn (thứ tự bắt buộc)

```bash
cd terraform/aws && terraform init && terraform plan && terraform apply   # 1. Hạ tầng
cd ansible/aws && cp inventory.ini.example inventory.ini                   # 2. Điền IP từ terraform output
ansible-playbook -i aws/inventory.ini common/mtls_setup.yml -C             # 3. (dry-run trước)
ansible-playbook -i aws/inventory.ini common/vm2_challenge.yml             # 4. VM2 trước
ansible-playbook -i aws/inventory.ini aws/vm1_web.yml                      # 5. VM1 sau
# 6. Cloudflare DNS A record → VM1 public IP (proxy cam)
```

⚠️ **Điểm cần biết**: `aws/vm1_web.yml` hiện chạy **PostgreSQL container trên VM1**
(`DATABASE_URL=postgresql://ctfd:...@db:5432/ctfd`), KHÔNG dùng RDS dù Terraform đã
provision RDS + SSM `/ctfd/database-url`. Hai phương án khi deploy: (A) giữ nguyên như
playbook (đơn giản, chi phí thấp hơn), (B) chuyển sang RDS bằng cách inject
`DATABASE_URL` từ SSM — xem `.claude/architecture/03-data-and-storage.md`.

## 5. Cú sốc ứng dụng CTFd (docs/common/02)

- CTFd cache template trong **Redis** — sửa template xong phải `FLUSHALL` trong container redis.
- `uploads/` phải thuộc **UID 1001** (user ctfd trong container).
- Plugin **ctfd-whale** pin `docker==4.1.0` quá cũ → Dockerfile custom override `docker==7.1.0`.
- **Cấu hình CTFd-Whale**: Đã thiết lập qua đường hầm FRP (VM2 frpc -> VM1 frps). Nếu có lỗi mất kết nối Docker API hoặc FRPC Admin API, cần đảm bảo `ctfd_frp_containers` overlay network trên VM2 có subnet không trùng lặp (vd: `10.20.0.0/16`) và file `update_whale.sql` đã được nạp đúng thông số IP/Token.
- FRP: frps trên VM1 (control 7000, dashboard 7400 loopback, vhost 8080), challenge ports 10000–10100.

## 6. Agent workflow nhanh

| Việc | Dùng |
|---|---|
| Deploy end-to-end | slash command `/aws-deploy` |
| Kiểm tra sức khỏe | `/aws-status`, `/aws-logs` |
| SSH VM1/VM2 | `/aws-ssh` |
| Sửa theme + flush Redis | `/aws-theme-deploy` |
| Validate IaC | `/aws-validate` hoặc `.claude/scripts/validate-all.ps1` |
| Chi phí | `/aws-cost` |
| Diễn biến sự cố | `/aws-troubleshoot` + agent `incident-responder` |

## 7. Hệ sinh thái `.claude/`

- `skills/ctfd-aws/` — 8 skill chuyên biệt cho repo này (tự động load khi relevant).
- `skills/vendored/` — skills DevOps clone từ upstream (anthropics, superpowers, wshobson-agents); cập nhật bằng `/skills-update`.
- `commands/` — slash commands vận hành AWS.
- `hooks/` — Python guards chạy PreToolUse/PostToolUse/SessionStart (cấu hình trong `settings.json`).
- `agents/` — subagent chuyên trách (terraform, ansible, incident, security).
- `scripts/` — setup env dev Windows/Linux, validate, test hooks.
