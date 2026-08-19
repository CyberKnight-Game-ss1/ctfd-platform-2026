# Xử lý sự cố trên AWS

## Câu lệnh thường dùng

### Kiểm tra trạng thái EC2

```bash
# Lấy instance IDs
cd terraform/aws
VM1_ID=$(terraform output -raw vm1_instance_id)
VM2_ID=$(terraform output -raw vm2_instance_id)

# Xem trạng thái instances
aws ec2 describe-instances \
  --instance-ids $VM1_ID $VM2_ID \
  --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}" \
  --output table \
  --region ap-southeast-1
```

### SSH vào EC2 qua SSM Session Manager

```bash
# Cài SSM Session Manager plugin (một lần):
# macOS: brew install session-manager-plugin
# Linux: Xem https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# SSH vào VM1 (không cần key pair, không cần port 22 mở)
aws ssm start-session --target $VM1_ID --region ap-southeast-1

# SSH vào VM2
aws ssm start-session --target $VM2_ID --region ap-southeast-1
```

### Docker trên VM1

```bash
# SSH vào VM1 qua SSM rồi chạy các lệnh sau:

# Xem các container đang chạy
sudo docker ps

# Xem logs CTFd realtime
sudo docker logs -f ctfd_ctfd_1

# Khởi động lại CTFd
cd /opt/ctfd
DB_URL=$(aws ssm get-parameter --name /ctfd/database-url --with-decryption --query Parameter.Value --output text --region ap-southeast-1)
sudo DATABASE_URL="$DB_URL" docker-compose restart ctfd

# Flush Redis cache (sau khi cập nhật template HTML)
sudo docker exec ctfd_cache_1 redis-cli FLUSHALL
```

### RDS PostgreSQL

```bash
# Xem thông tin RDS instance
aws rds describe-db-instances \
  --db-instance-identifier ctf-postgres \
  --region ap-southeast-1

# Lấy endpoint của RDS
aws rds describe-db-instances \
  --db-instance-identifier ctf-postgres \
  --query "DBInstances[0].Endpoint.Address" \
  --output text \
  --region ap-southeast-1

# Test kết nối từ VM1 (SSH vào VM1 trước qua SSM)
nc -zv <RDS_ENDPOINT> 5432
```

### Lấy secrets từ SSM Parameter Store

```bash
# Lấy DATABASE_URL
aws ssm get-parameter \
  --name "/ctfd/database-url" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ap-southeast-1

# Cập nhật DATABASE_URL mới (nếu cần đổi password)
aws ssm put-parameter \
  --name "/ctfd/database-url" \
  --value "postgresql://ctfd:NEW_PASSWORD@<RDS_ENDPOINT>:5432/ctfd" \
  --type SecureString \
  --overwrite \
  --region ap-southeast-1
```

### Xem CloudWatch Logs

```bash
# Xem Nginx access log (theo dõi realtime)
aws logs tail /ctfd/nginx/access --follow --region ap-southeast-1

# Xem Nginx error log
aws logs tail /ctfd/nginx/error --follow --region ap-southeast-1

# Tìm kiếm lỗi trong 1 giờ gần nhất
aws logs filter-log-events \
  --log-group-name /ctfd/nginx/error \
  --start-time $(date -d '1 hour ago' +%s000) \
  --region ap-southeast-1
```

### Bật/Tắt VM2 thủ công

```bash
# Tắt VM2
aws ec2 stop-instances --instance-ids $VM2_ID --region ap-southeast-1

# Bật VM2
aws ec2 start-instances --instance-ids $VM2_ID --region ap-southeast-1

# Xem EventBridge schedules (tự động bật/tắt)
aws scheduler list-schedules --region ap-southeast-1
```

## Lỗi thường gặp

### PermissionError: [Errno 13] khi upload file trong CTFd Admin

**Nguyên nhân:** Thư mục `/opt/ctfd/uploads` thuộc `root:root`, CTFd container chạy với user `ctfd` (UID 1001) không có quyền ghi.

**Giải pháp (chạy qua SSM):**
```bash
aws ssm send-command \
  --instance-ids $VM1_ID \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands":["sudo chown -R 1001:1001 /opt/ctfd/uploads","sudo chmod -R 755 /opt/ctfd/uploads"]}' \
  --region ap-southeast-1
```

### CTFd không kết nối được RDS

**Kiểm tra Security Group:**
```bash
# Xem Security Group của RDS
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ctf-sg-db" \
  --region ap-southeast-1

# Đảm bảo sg_web được allow inbound vào sg_db port 5432
```

**Kiểm tra DATABASE_URL:**
```bash
# Lấy DATABASE_URL hiện tại
aws ssm get-parameter --name /ctfd/database-url --with-decryption --output text --region ap-southeast-1

# RDS endpoint có thể thay đổi nếu instance bị recreate, cần cập nhật SSM parameter
```

### SSM Session Manager báo lỗi "Instance not connected"

**Nguyên nhân:** SSM Agent chưa kết nối, hoặc IAM Role chưa có policy `AmazonSSMManagedInstanceCore`.

**Kiểm tra:**
```bash
# Xem trạng thái SSM của instance
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$VM1_ID" \
  --region ap-southeast-1

# Nếu không thấy instance trong danh sách:
# 1. Đợi thêm 3-5 phút sau khi EC2 khởi động
# 2. Kiểm tra IAM Role của EC2 có policy AmazonSSMManagedInstanceCore chưa
```

### EC2 Spot Instance (VM2) bị interrupt

**Nguyên nhân:** AWS thu hồi Spot Instance khi nhu cầu tăng cao.

**Giải pháp:**
```bash
# Xem lý do interrupt
aws ec2 describe-spot-instance-requests \
  --region ap-southeast-1 \
  --query "SpotInstanceRequests[*].{State:State,Status:Status.Code,Message:Status.Message}"

# Khởi động lại VM2 (EventBridge Scheduler cũng sẽ tự bật vào 07:30 sáng)
aws ec2 start-instances --instance-ids $VM2_ID --region ap-southeast-1
```

### Alpine.js không hoạt động / Form không submit được

**Giải pháp:** Xem `docs/common/01-theme-and-frontend.md` để biết cách thay thế bằng Vanilla JS.

### Email xác nhận vào Spam

**Giải pháp:** Tương tự GCP - kiểm tra SPF/DKIM cho Gmail SMTP, hướng dẫn user kiểm tra Spam folder.
