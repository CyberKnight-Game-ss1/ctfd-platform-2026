# gen-inventory.ps1 — Sinh ansible/aws/inventory.ini từ terraform output
# USER tự chạy script này trong terminal (agent không tự ghi file inventory).
# Dùng: pwsh -File .claude/scripts/gen-inventory.ps1
#
# CHẾ ĐỘ SSM (mặc định, dùng cho hạ tầng này):
#   Cụm EC2 KHÔNG gắn key pair và Security Group KHÔNG mở port 22
#   -> không thể SSH bằng key. Ansible kết nối qua plugin `amazon.aws.aws_ssm`
#   (SSM Session Manager API), cần trên control node:
#     - collection amazon.aws (đã có)
#     - boto3            (đã có)
#     - binary session-manager-plugin (bắt buộc — plugin tự tìm trong PATH
#       hoặc /usr/local/bin/session-manager-plugin)
#   Vì plugin nhận `ansible_host` = INSTANCE ID, inventory KHÔNG chứa IP nào.
#
# Chạy Ansible từ WSL Ubuntu (Windows không chạy được ansible-core làm control node):
#   wsl -d Ubuntu -- bash -lc "cd /mnt/d/ctfd-platform-2026 && ansible-playbook -i ansible/aws/inventory.ini ansible/common/vm2_challenge.yml -C --diff"
$ErrorActionPreference = "Stop"

Push-Location terraform/aws
try {
    $vm1Id    = terraform output -raw vm1_instance_id
    $vm2Id    = terraform output -raw vm2_instance_id
    $bucket   = terraform output -raw s3_bucket_name
    $vm1Ip    = terraform output -raw vm1_web_public_ip
    $vm2Ip    = terraform output -raw vm2_challenge_public_ip
} finally { Pop-Location }

if (-not $vm1Id -or -not $vm2Id) { throw "Thiếu terraform output — đã chạy terraform apply chưa?" }

$dest = "ansible/aws/inventory.ini"
$content = @"
# Inventory AWS — sinh tự động $(Get-Date -Format 'yyyy-MM-dd HH:mm') bởi gen-inventory.ps1
# KHÔNG COMMIT file này (đã gitignore).
# Chế độ SSM: ansible_host = INSTANCE ID (không cần SSH key, không mở port 22).
# IP public chỉ ghi trong comment để tra cứu — Ansible KHÔNG dùng IP để kết nối.

[vm1_web]
# public IP (chỉ để tham khảo / trỏ DNS Cloudflare): $vm1Ip
ctf-vm1-web ansible_host=$vm1Id

[vm2_challenge]
# public IP (chỉ để tham khảo): $vm2Ip
ctf-vm2-challenge ansible_host=$vm2Id

[all:vars]
ansible_connection=amazon.aws.aws_ssm
ansible_aws_ssm_region=ap-southeast-1
ansible_aws_ssm_bucket_name=$bucket
ansible_aws_ssm_timeout=120
ansible_python_interpreter=/usr/bin/python3
aws_region=ap-southeast-1
"@

Set-Content -Path $dest -Value $content -Encoding utf8
Write-Host "Đã ghi $dest (chế độ SSM: VM1=$vm1Id, VM2=$vm2Id, bucket=$bucket)" -ForegroundColor Green
Write-Host ""
Write-Host "Chạy Ansible từ WSL Ubuntu, ví dụ:" -ForegroundColor Yellow
Write-Host '  wsl -d Ubuntu -- bash -lc "cd /mnt/d/ctfd-platform-2026 && ansible-playbook -i ansible/aws/inventory.ini ansible/common/vm2_challenge.yml -C --diff"'
