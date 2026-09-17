---
description: Mở phiên SSM vào VM1 hoặc VM2, hoặc sinh lệnh scp qua SSM proxy
argument-hint: "[vm1 | vm2 | scp]"
---

## Nhiệm vụ

Target: **$ARGUMENTS** (mặc định `vm1`).

1. Lấy instance id: `terraform -chdir=terraform/aws output -raw vm1_instance_id` (hoặc `vm2_instance_id`).
2. Kiểm tra SSM ping: `aws ssm describe-instance-information --filters "Key=InstanceIds,Values=<id>" --region ap-southeast-1`
   - Nếu `PingStatus != Online`: gợi ý chờ 2-3 phút, kiểm tra instance đã start + có SG egress 443.
3. Target `vm1`/`vm2`: chạy `aws ssm start-session --target <id> --region ap-southeast-1`.
   (Lệnh này mở session tương tác — nếu terminal không hỗ trợ, in ra lệnh để user tự chạy + nhắc cài Session Manager plugin.)
4. Target `scp`: in sẵn template scp/ssh qua ProxyCommand SSM (dùng pattern trong `.claude/skills/ctfd-aws/ctfd-aws-operations/SKILL.md`).

Lưu ý: KHÔNG bao giờ đề xuất mở port 22 hay SSH trực tiếp qua IP public.
