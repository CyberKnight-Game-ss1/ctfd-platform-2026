# Xử lý sự cố trên GCP

## Câu lệnh thường dùng

### Kiểm tra trạng thái VM

```bash
# Xem danh sách instances
gcloud compute instances list

# Xem logs của một instance
gcloud compute instances get-serial-port-output ctf-vm1-web --zone=asia-southeast1-a
```

### Docker trên VM1

```bash
# SSH vào VM1 qua IAP
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap

# Xem các container đang chạy
sudo docker ps

# Xem logs CTFd realtime
sudo docker logs -f ctfd_ctfd_1

# Khởi động lại CTFd
cd /opt/ctfd && sudo DATABASE_URL='<url>' docker-compose restart ctfd

# Flush Redis cache (sau khi cập nhật template HTML)
sudo docker exec ctfd_cache_1 redis-cli FLUSHALL
```

### Cloud SQL

```bash
# Xem thông tin Cloud SQL instance
gcloud sql instances describe ctf-postgres-instance

# Kết nối trực tiếp vào Cloud SQL qua Cloud SQL Auth Proxy
gcloud sql connect ctf-postgres-instance --user=ctfd --database=ctfd
```

### Secret Manager

```bash
# Xem DATABASE_URL đã lưu
gcloud secrets versions access latest --secret="ctfd-db-connection"
```

### Xem Cloud Logs

```bash
# Xem Nginx logs
gcloud logging read 'resource.type="gce_instance" AND logName:"nginx"' --limit=50

# Xem tất cả logs của VM1 trong 1 giờ gần đây
gcloud logging read 'resource.labels.instance_id="<INSTANCE_ID>"' \
  --freshness=1h --limit=100
```

## Lỗi thường gặp

### PermissionError: [Errno 13] khi upload file trong CTFd Admin

**Nguyên nhân:** Thư mục `/opt/ctfd/uploads` thuộc `root:root`, CTFd container chạy với user `ctfd` (UID 1001) không có quyền ghi.

**Giải pháp:**
```bash
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap --command="
  sudo chown -R 1001:1001 /opt/ctfd/uploads
  sudo chmod -R 755 /opt/ctfd/uploads
"
```

### CTFd không kết nối được Database

**Kiểm tra:**
```bash
# Xem DATABASE_URL hiện tại
gcloud secrets versions access latest --secret="ctfd-db-connection"

# Test kết nối từ VM1 đến Cloud SQL private IP
gcloud compute ssh ubuntu@ctf-vm1-web --tunnel-through-iap --command="
  nc -zv <CLOUD_SQL_PRIVATE_IP> 5432
"
```

### Alpine.js không hoạt động / Form không submit được

**Nguyên nhân:** Xung đột giữa Alpine.js và script tùy chỉnh.
**Giải pháp:** Xem `docs/common/01-theme-and-frontend.md` để biết cách thay thế bằng Vanilla JS.

### Email xác nhận vào Spam

**Giải pháp:**
- Thêm SPF record trên Cloudflare DNS cho Gmail SMTP.
- Hướng dẫn user kiểm tra Spam/Junk folder.
- Domain `tdtu.edu.vn` và `student.tdtu.edu.vn` có spam filter chặt, phải chờ 1-2 phút.

### VM2 bị Preempted (Spot instance bị thu hồi)

```bash
# Kiểm tra trạng thái VM2
gcloud compute instances describe ctf-vm2-challenge --zone=asia-southeast1-a

# Khởi động lại VM2
gcloud compute instances start ctf-vm2-challenge --zone=asia-southeast1-a

# Xem lý do preemption trong Audit Logs
gcloud logging read 'protoPayload.methodName="v1.compute.instances.stop"' --limit=5
```
