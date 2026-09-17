output "vm1_web_public_ip" {
  description = "Public IP của VM1 (Web Server) - dùng để trỏ DNS Cloudflare (là Elastic IP, không đổi khi stop/start)"
  value       = aws_eip.vm1_web.public_ip
}

output "vm1_web_elastic_ip_id" {
  description = "Allocation ID của Elastic IP gắn VM1 — dùng khi cần release (aws ec2 release-address)"
  value       = aws_eip.vm1_web.id
}

output "vm2_challenge_public_ip" {
  description = "Public IP của VM2 (Challenge Server)"
  value       = aws_instance.vm2_challenge.public_ip
}

output "vm1_instance_id" {
  description = "EC2 Instance ID của VM1 - dùng cho SSM Session Manager"
  value       = aws_instance.vm1_web.id
}

output "vm2_instance_id" {
  description = "EC2 Instance ID của VM2 - dùng cho SSM Session Manager"
  value       = aws_instance.vm2_challenge.id
}

output "rds_endpoint" {
  description = "Endpoint của RDS PostgreSQL (chỉ truy cập được từ VM1 qua sg_db) — null khi use_rds = false"
  value       = var.use_rds ? aws_db_instance.ctf_postgres[0].endpoint : null
}

output "database_url_ssm_parameter" {
  description = "Tên SSM Parameter lưu DATABASE_URL (null khi use_rds = false; đọc bằng: aws ssm get-parameter --name /ctfd/database-url --with-decryption)"
  value       = var.use_rds ? aws_ssm_parameter.db_url[0].name : null
}

output "s3_bucket_name" {
  description = "Tên S3 bucket lưu PCAP và backups"
  value       = aws_s3_bucket.ctf_storage.bucket
}
