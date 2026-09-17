#!/usr/bin/env bash
# ============================================================
# check-vm1.sh — Kiểm tra sức khoẻ VM1 (Web Server)
# Chạy qua SSM (không cần SSH):
#   pwsh -File .claude/scripts/ssm-run.ps1 -InstanceId <VM1_ID> -ScriptFile .claude/scripts/check-vm1.sh
# Dùng trong after-deploy checklist (skill ctfd-aws-deploy).
# ============================================================

echo "=== CONTAINERS ==="
docker ps -a --format '{{.Names}} | {{.Status}}'

echo "=== HTTP (local) ==="
curl -s -o /dev/null -w 'http_code=%{http_code}\n' http://127.0.0.1:80/

echo "=== HTTPS (local, self-signed) ==="
curl -sk -o /dev/null -w 'http_code=%{http_code}\n' https://127.0.0.1:443/

echo "=== SERVICES ==="
echo -n "nginx: "; systemctl is-active nginx
echo -n "amazon-cloudwatch-agent: "; systemctl is-active amazon-cloudwatch-agent
echo -n "frps: "; systemctl is-active frps 2>/dev/null || echo "n/a"

echo "=== SSM PARAM (DB secret không in ra) ==="
ls -la /opt/ctfd/.env 2>/dev/null || echo "chưa có /opt/ctfd/.env"

echo "=== THEME ==="
ls /opt/ctfd/themes/ 2>/dev/null

echo "=== DISK ==="
df -h / | tail -1

echo "=== MEM ==="
free -m | head -2

echo "=== NGINX LOG (forensics) ==="
ls -la /var/log/nginx/ 2>/dev/null | tail -4