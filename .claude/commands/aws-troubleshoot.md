---
description: Chẩn đoán sự cố cụm CTFd theo runbook 4 pha (triệu chứng → tầng → kiểm tra → khắc phục)
argument-hint: "<mô-tả-triệu-chứng>"
---

## Nhiệm vụ

Triệu chứng user báo: **$ARGUMENTS**.

1. Load skill `.claude/skills/ctfd-aws/ctfd-aws-troubleshoot/SKILL.md` — làm đúng 4 pha.
2. Pha 1: đặt câu hỏi làm rõ (mọi user hay 1? mã HTTP? bắt đầu khi nào? liên quan change nào gần đây?).
3. Pha 2: chạy bộ kiểm tra từ ngoài vào trong (EC2 status → CloudWatch logs → SSM vào VM1 → docker/redis/db/whale). Mỗi bước ghi kết quả ngắn.
4. Pha 3: đề xuất fix ít rủi ro nhất trước, từng bước một, xin xác nhận khi lệnh có tác động (restart, flush cache...).
5. Pha 4: sau khi hết sự cố — đề xuất alarm CloudWatch + ghi root cause vào `docs/aws/02-aws-troubleshooting.md` qua PR.

Nguyên tắc: KHÔNG đoán mò sửa nhiều thứ cùng lúc; mỗi thay đổi phải kèm lý do + cách verify.
