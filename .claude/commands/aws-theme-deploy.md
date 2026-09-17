---
description: Deploy file theme/frontend lên VM1 qua SSM (scp) và flush Redis cache CTFd
argument-hint: "<đường-dẫn-file-trong-themes/> ..."
---

## Nhiệm vụ

Files: **$ARGUMENTS** (rỗng = hỏi user chỉ rõ file, KHÔNG deploy cả thư mục).

Quy trình:
1. Xác minh các file tồn tại trong `themes/ctfd-theme-neubrutalism/` (template/static).
2. Lấy VM1 id: `terraform -chdir=terraform/aws output -raw vm1_instance_id`.
3. Upload qua SSM proxy:
   `scp -o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region ap-southeast-1" <file> ubuntu@$VM1_ID:/home/ubuntu/`
   (scp tương tác — nếu không chạy được thì in lệnh cho user.)
4. Copy vào đúng chỗ + flush Redis bằng SSM Run Command:
   `aws ssm send-command --instance-ids $VM1_ID --document-name "AWS-RunShellScript" --region ap-southeast-1 --parameters commands=["sudo cp /home/ubuntu/<file> /opt/ctfd/themes/ctfd-theme-neubrutalism/<đường-dẫn>","sudo docker exec ctfd_cache_1 redis-cli FLUSHALL"]`
5. Xác minh: `aws logs tail /ctfd/nginx/access --region ap-southeast-1` không lỗi 5xx; nhắc user hard-refresh (Ctrl+F5).

Lưu ý: CTFd cache template trong Redis → KHÔNG bao giờ bỏ qua bước FLUSHALL.
