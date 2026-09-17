# Kiến trúc AWS — CyberKnight CTFd Platform 2026

Tài liệu kiến trúc **nguồn sự thật cho AI agent** — nội dung đối chiếu trực tiếp với
code trong `terraform/aws/`, `ansible/`, `challenges/k8s/` (tháng 2026). Khi code đổi,
tài liệu này phải đổi trong cùng PR.

## Sơ đồ tổng thể

```mermaid
flowchart TB
    subgraph Internet
        P[Player / Spectator]
    end
    P -->|HTTPS cyberknightgame.site| CF

    subgraph Edge
        CF[Cloudflare — DNS + WAF + CDN + SSL\nproxy cam, A record → VM1 public IP]
    end

    subgraph AWS["AWS ap-southeast-1 (Singapore)"]
        subgraph VPC["VPC ctf-vpc — 10.0.0.0/16 + IGW"]
            subgraph S1["Public Subnet 1 (10.0.1.0/24, AZ-a)"]
                VM1["EC2 ctf-vm1-web — t3.small\nUbuntu 22.04, IMDSv2 required\nNginx:80 → CTFd:8000 → Redis:6379\nFRPS:7000 (VPC-only) + FRP challenge ports 10000-10100\nPostgreSQL container (mode A) / client RDS (mode B)"]
                VM2["EC2 ctf-vm2-challenge — m7i-flex.large Spot (8GB)\nDocker Engine + docker-socket-proxy (127.0.0.1:2376)\nFRPC → VM1:7000 · K3s v1.28.2 + nsjail\ntcpdump PCAP rotate 30m"]
            end
            subgraph S2["Public Subnet 2 (10.0.2.0/24, AZ-b)"]
                RDS[("RDS PostgreSQL 15 ctf-postgres\ndb.t3.micro, encrypted, private only\nsg_db: 5432 chỉ từ sg_web")]
            end
        end
        S3B[("S3 ctf-storage-<rand>\nPCAP + backup — Block Public + AES256\nLifecycle: 7d → IA, 30d → Glacier")]
        SSM["SSM Parameter Store\n/ctfd/database-url (SecureString)"]
        EB["EventBridge Scheduler\nstop-vm2 00:00 ICT · start-vm2 07:30 ICT"]
        CW["CloudWatch Logs\n/ctfd/nginx/access · /ctfd/nginx/error · /ctfd/application"]
    end

    CF -->|80/443 chỉ từ Cloudflare IP ranges| VM1
    VM1 -->|5432 qua sg_db| RDS
    VM1 <-->|FRP tunnel 7000 (Docker API encrypted)| VM2
    VM2 -.upload PCAP.-> S3B
    VM1 -.log.-> CW
    EB -.stop/start.-> VM2
    VM1 -.read secret.-> SSM
```

## Các tài liệu con

| File | Nội dung |
|---|---|
| [01-network.md](01-network.md) | VPC, subnets, IGW, route table, 3 Security Groups, Cloudflare allowlist, FRP ports |
| [02-compute.md](02-compute.md) | VM1/VM2, AMI, IMDSv2, Spot, IAM role/instance profile |
| [03-data-and-storage.md](03-data-and-storage.md) | RDS, SSM, S3, **phương án DB A/B (container vs RDS)** |
| [04-security.md](04-security.md) | Ma trận hardening, secrets lifecycle, threat model CTF |
| [05-observability.md](05-observability.md) | CloudWatch Agent, log groups, tcpdump, schedules |
| [06-deployment.md](06-deployment.md) | Pipeline deploy 6 bước, rollback, drift handling |
| [07-cost.md](07-cost.md) | Cost model, practice vs competition, tối ưu |

## Nguyên tắc kiến trúc (đọc trước mọi thiết kế mới)

1. **Người chơi tấn công platform** — IMDSv2, sandbox, allowlist là hàng rào sống còn.
2. **Origin ẩn sau Cloudflare** — không IP nào của origin phải public ngoài challenge ports.
3. **IaC-first** — mọi thay đổi qua Terraform/Ansible; console chỉ cho khẩn cấp, sau đó quay lại sync code.
4. **Chi phí sinh viên** — Spot + schedule tắt ban đêm + lifecycle S3; flipping production có checklist riêng.
5. **Hai máy ảo là đủ** — không nâng cấp orchestration trừ khi quy mô buộc phải vậy.
