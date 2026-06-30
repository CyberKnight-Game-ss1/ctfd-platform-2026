# Infrastructure and Configuration

## Overview
CyberKnight Weekly Game 2026 runs on CTFd.
- Domain: `cyberknightgame.site`
- Infra: GCP Compute Engine (`ctf-vm1-web`) provisioned via Terraform
- Edge: Cloudflare (DNS, SSL, DDoS protection)
- Stack: Docker Compose (CTFd, MariaDB, Redis)

## Email Configuration
- Provider: Gmail SMTP
- SMTP Server: `smtp.gmail.com`
- Port: `587`
- TLS: Enabled
- Domain Allowlist: Configured in CTFd Admin -> Config. Must be comma-separated on a single line (e.g. `student.tdtu.edu.vn,tdtu.edu.vn`). Newlines break the parser.

## File Uploads
The CTFd container runs as user `ctfd` (UID 1001). The bind mount for `/opt/ctfd/uploads` to `/var/uploads` on the host MUST have ownership `1001:1001`.
- Command to fix: `sudo chown -R 1001:1001 /opt/ctfd/uploads`
- If ownership is `root:root`, file uploads in the Admin Panel will throw a `PermissionError: [Errno 13]`.
