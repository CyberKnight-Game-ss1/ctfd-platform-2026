---
description: Quản lý VM2 challenge server (start/stop thủ công, xem trạng thái Spot/schedules)
argument-hint: "[status | start | stop]"
---

## Nhiệm vụ

Mode: **$ARGUMENTS** (mặc định `status`).

- `status`: describe VM2 (state, type, lifecycle=spot/on-demand, IP) + list EventBridge schedules.
- `start`/`stop`: `aws ec2 start-instances|stop-instances --instance-ids <vm2_id> --region ap-southeast-1` — đây là lệnh nhánh `ask` trong permissions; trình bày tác động (stop = ngừng mọi challenge động đang chạy; các player sẽ mất instance Whale) và xin xác nhận trước.

Sau khi `start`: chờ ~2 phút, xác nhận SSM online + K3s node Ready (qua SSM: `k3s kubectl get nodes`).

Nhắc user: lịch tự động là stop 00:00 / start 07:30 ICT (EventBridge) — thao tác thủ công có thể bị lịch ghi đè.
