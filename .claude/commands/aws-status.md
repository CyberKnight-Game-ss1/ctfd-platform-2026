---
description: Kiểm tra sức khỏe hạ tầng AWS của cụm CTFd (EC2, SSM, RDS, S3, scheduler, outputs)
allowed-tools: Bash(aws:*), Bash(terraform:*)
---

## Nhiệm vụ

Health check đầy đủ, trình bày dạng bảng trạng thái:

1. Identity: `aws sts get-caller-identity --region ap-southeast-1`
2. Terraform outputs: `terraform -chdir=terraform/aws output` (nếu state chưa tồn tại thì dừng, báo user chưa deploy)
3. EC2 VM1/VM2: `aws ec2 describe-instances --region ap-southeast-1 --filters "Name=tag:Project,Values=CyberKnight-CTF" --query "Reservations[].Instances[].{Id:InstanceId,Name:Tags[?Key=='Name']|[0].Value,State:State.Name,Type:InstanceType,IP:PublicIpAddress,AZ:Placement.AvailabilityZone}" --output table`
4. SSM online: `aws ssm describe-instance-information --region ap-southeast-1 --query "InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Name:ComputerName}" --output table`
5. RDS: `aws rds describe-db-instances --db-instance-identifier ctf-postgres --region ap-southeast-1 --query "DBInstances[].{Status:DBInstanceStatus,Class:DBInstanceClass,Endpoint:Endpoint.Address,Public:PubliclyAccessible}" --output table`
6. S3: `aws s3 ls --region ap-southeast-1 | Select-String ctf-storage` (hoặc grep tương đương)
7. Schedules: `aws scheduler list-schedules --region ap-southeast-1 --query "Schedules[].{Name:Name,State:State,Expr:ScheduleExpression}" --output table`

Kết luận: cụm đang ở trạng thái nào (đầy đủ / thiếu gì / VM2 đang tắt?), có vấn đề gì cần xử lý ngay không.
