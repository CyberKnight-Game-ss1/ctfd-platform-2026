---
description: Phân tích chi phí AWS của cụm CTFd (cost explorer theo service + so mô hình lý thuyết)
---

## Nhiệm vụ

1. `aws ce get-cost-and-usage --time-period Start=<đầu-tháng>,End=<hôm-nay> --granularity MONTHLY --metrics "UnblendedCost" --group-by Type=DIMENSION,Key=SERVICE --region ap-southeast-1` — tổng tiền hiện tại trong tháng.
2. Nếu được, lấy 3 tháng trước để so xu hướng.
3. So với mô hình lý thuyết trong `.claude/skills/ctfd-aws/ctfd-aws-cost/SKILL.md` (~$50-60/tháng luyện tập).
4. Đưa ra top 3 đề xuất tiết kiệm phù hợp trạng thái hiện tại (Spot VM2? RDS có dùng không? log retention? Reserved Instance?).

Nếu `ce:GetCostAndUsage` bị từ chối (account thiếu quyền): báo user bật trong console hoặc gán quyền, và trình bày phân tích lý thuyết thay thế.
