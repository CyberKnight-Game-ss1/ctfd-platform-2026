# 04 — Security & Threat Model

> Nguồn sự thật: `terraform/aws/{network,compute,database}.tf`, `ansible/common/*`, `challenges/k8s/*`

## Threat model đặc thù CTF

Kẻ tấn công = **người chơi hợp lệ**. Họ được giao chính thức:
- URL web có Web Exploitation challenge (SSRF, RCE-style payloads bình thường hoá)
- Port netcat trên 10000-10100 → binary/PWN challenge
- Sandbox container để phá

⇒ Mỗi hàng rào dưới đây được thiết kế cho scenario đó.

## Ma trận kiểm soát

| Layer | Kiểm soát | File code | Verify lệnh |
|---|---|---|---|
| Edge | Cloudflare WAF/DDoS/SSL, origin ẩn | (Cloudflare dashboard) | A record proxy cam |
| Origin ingress | SG chỉ nhận 15 dải Cloudflare | `network.tf` | `aws ec2 describe-security-groups` |
| IAM credential theft | IMDSv2 required + hop-limit 1 | `compute.tf` | curl metadata từ container phải fail |
| Docker API exposure | socket-proxy **loopback-only** + allowlist tối thiểu | `vm2_challenge.yml` | `ss -tlnp \| grep 2376` trên VM2 |
| VM2 exposure | SG zero-inbound | `network.tf` | port scan từ ngoài phải timeout |
| DB exposure | private + SG từ sg_web + encrypted | `database.tf` | `publicly_accessible=false` |
| Sandbox | K3s NetworkPolicy deny-all egress + nsjail (drop caps, seccomp) | `challenges/k8s/network_policy.yaml`, `nsjail_pod.yaml` | pod không curl ra ngoài |
| Secrets at rest | SSM SecureString; S3 AES256; EBS encrypted | `database.tf`, `storage_and_automation.tf` | |
| Forensics | tcpdump docker0, rotate 30m, giữ 48 file | `vm2_challenge.yml` | `/var/log/ctf-pcap/` có file mới |

## Secrets inventory & vòng đời

| Secret | Nơi lưu | Rotate thế nào |
|---|---|---|
| RDS password | `terraform.tfvars` local + SSM `/ctfd/database-url` | đổi tfvars → `terraform apply` → update SSM → restart ctfd |
| CTFd SECRET_KEY | extra-vars khi chạy playbook | đổi + restart ctfd (⚠️ logout toàn user) |
| FRP token | trong `frps.ini` (playbook) | đổi 2 đầu frps/frpc cùng lúc |
| mTLS CA/keys | `scripts/mtls_certs/` local, gitignored | chạy lại `common/mtls_setup.yml` |
| AWS credentials | `~/.aws` / IAM Identity Center | theo chuẩn AWS |

**Hardcode cần rotate trước giải thật**: `secret_frp_token_2026`,
`change_me_in_production` — cả hai đang nằm trong playbook (protect_secrets hook
chặn agent in giá trị; con người vẫn phải tự thay).

## Sự cố bảo mật — phản ứng nhanh

| Triệu chứng | Hành động |
|---|---|
| Thấy request metadata 169.254.169.254 trong Nginx log | IMDSv2 đang chặn (hop 1) — xác nhận không có token nào trả về; review challenge đó |
| Container escape nghi ngờ | ngừng challenge, snapshot EBS VM2, tải PCAP lên S3, rollback bằng recreate VM2 từ playbook |
| Credential leak (repo/log/chat) | rotate ngay (bảng trên) + đánh giá thời gian exposure |
| SG bị mở nhầm 0.0.0.0/0 cho 80/443 | quay lại Cloudflare-only qua `terraform apply` (drift) |

## Nguyên tắc khi review PR hạ tầng

Mọi thay đổi phải trả lời: SSRF đọc thêm được gì? secret mới nằm đâu? người chơi
chạm được bề mặt mới nào? control chết thì fail-closed hay fail-open?
