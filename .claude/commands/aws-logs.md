---
description: Xem logs CloudWatch của cụm CTFd (nginx access/error, application) — realtime hoặc filter lỗi
argument-hint: "[nginx-access | nginx-error | app | errors] (mặc định: errors)"
---

## Nhiệm vụ

Stream: **$ARGUMENTS** (mặc định `errors`).

- `nginx-access` → `aws logs tail /ctfd/nginx/access --follow --region ap-southeast-1`
- `nginx-error` → `aws logs tail /ctfd/nginx/error --follow --region ap-southeast-1`
- `app` → `aws logs tail /ctfd/application --follow --region ap-southeast-1`
- `errors` (mặc định) → filter log ERROR/Traceback trong 24h qua trên cả 3 group:
  `aws logs filter-log-events --log-group-name <group> --start-time <epoch_ms-24h> --filter-pattern "?ERROR ?Traceback ?CRITICAL" --region ap-southeast-1`

Trước khi tail: `aws logs describe-log-groups --log-group-name-prefix /ctfd --region ap-southeast-1` để xác nhận group tồn tại (chưa tồn tại = CloudWatch Agent chưa chạy → vào VM1 kiểm tra agent qua SSM).

Tóm tắt phát hiện: lỗi gì, có pattern không, tầng nào chịu trách nhiệm, đề xuất bước xử lý (tham khảo skill `ctfd-aws-troubleshoot`).
