---
name: ctfd-aws-security
description: Checklist bảo mật cụm CTFd AWS — IMDSv2, Cloudflare-only ingress, mTLS/FRP tunnel, secrets handling, hardening trước thi đấu. Dùng khi review bảo mật, sửa SG/IAM, hoặc chuẩn bị giải đấu thật.
---

# Security Checklist — CTFd on AWS

Bối cảnh đặc thù: **nền tảng CTF chứa Web Exploitation challenge** — người chơi
chủ động tấn công platform. Mọi quyết định hardening xoay quanh điều này.

## Layer-based matrix

| Layer | Kiểm soát | Verify |
|---|---|---|
| Edge | Cloudflare WAF/DDoS/SSL; DNS chỉ qua Cloudflare | Proxy cam, SSL Full(strict) |
| Network | SG web nhận 80/443 **từ Cloudflare IP ranges duy nhất**; FRP 7000 **VPC-only**; challenge ports 10000-10100 public (bắt buộc cho gameplay) | `terraform/aws/network.tf` |
| Metadata | **IMDSv2 `required`, hop-limit 1** — chặn SSRF đọc IAM credentials từ container | `compute.tf metadata_options` |
| IAM | Instance role tối thiểu: SSM core, CloudWatch agent, SSM read-only | `compute.tf` |
| VM-to-VM | Docker API không bao giờ public — socket-proxy **loopback** trên VM2, CTFd gọi qua FRP tunnel mã hoá | `vm2_challenge.yml` |
| DB | RDS `publicly_accessible=false`, SG 5432 chỉ từ sg_web, storage encrypted, backup 7 ngày | `database.tf` |
| Sandbox | K3s NetworkPolicy deny-all egress + nsjail trong pod | `challenges/k8s/` |
| App | Registration whitelist `tdtu.edu.vn`, `student.tdtu.edu.vn` | CTFd config |
| Capture | tcpdump docker0 rotate 30m/48 file — bằng chứng khi có incident | systemd `ctf-tcpdump` |

## Luật secrets (agent + con người)

1. Secrets hợp lệ chỉ tồn tại: `terraform.tfvars` (local), SSM `/ctfd/database-url`, key mTLS local.
2. KHÔNG: commit tfstate/tfvars/pem/inventory.ini; in secret vào logs/chat/issue; hardcode vào playbook.
3. Vòng đời: rotate `db_password` → `terraform apply` + update SSM param + restart CTFd. Rotate FRP token trong `frps.ini`/compose đồng bộ 2 đầu.
4. Thấy secret lộ (git history, log) → coi như bị compromise: rotate ngay + lịch sử xóa phải dùng git filter BFG (risk — làm có kế hoạch).

## Hardening trước thi đấu thật

- [ ] `deletion_protection=true` (RDS), `skip_final_snapshot=false`
- [ ] S3 `force_destroy=false`
- [ ] VM2 `is_practice_mode=false` (On-Demand, không bị interrupt giữa giải)
- [ ] Đổi token FRP khỏi giá trị mặc định trong repo (`secret_frp_token_2026` → giá trị từ SSM/extra-vars)
- [ ] Đổi SECRET_KEY CTFd khỏi `change_me_in_production` (nếu chưa)
- [ ] Giới hạn SG 10000-10100 theo dải IP thi đấu nếu thi onsite
- [ ] CloudWatch alarm: 5xx spike, RDS connections, CPU VM1
- [ ] Snapshot RDS trước mở cổng đăng ký

## Khi review một change bảo mật

Hỏi: (1) SSRF liệu có đọc được gì mới? (2) secret mới nằm ở đâu, 누 có thể đọc? (3) người chơi
có chạm được tầng nào mới không? (4) fail-closed hay fail-open khi control chết?
