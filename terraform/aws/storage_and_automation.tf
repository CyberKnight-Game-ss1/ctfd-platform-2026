# Random suffix để tên S3 bucket là unique toàn cầu
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ============================================================
# S3 Bucket - lưu PCAP traffic và database backups
# ============================================================
resource "aws_s3_bucket" "ctf_storage" {
  bucket        = "ctf-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true  # Đổi thành false khi thi đấu thật

  tags = {
    Name    = "ctf-storage"
    Project = "CyberKnight-CTF"
  }
}

# Tắt public access hoàn toàn cho bucket (backup/PCAP không cần public)
resource "aws_s3_bucket_public_access_block" "ctf_storage" {
  bucket = aws_s3_bucket.ctf_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bật mã hóa AES-256 at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "ctf_storage" {
  bucket = aws_s3_bucket.ctf_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rules:
#   - Sau 7 ngày:  chuyển sang STANDARD_IA  (tiết kiệm ~45% so với STANDARD)
#   - Sau 30 ngày: chuyển sang GLACIER       (tiết kiệm ~80% so với STANDARD)
resource "aws_s3_bucket_lifecycle_configuration" "ctf_storage" {
  bucket = aws_s3_bucket.ctf_storage.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

# ============================================================
# IAM Role cho EventBridge Scheduler để gọi SSM Automation
# ============================================================
resource "aws_iam_role" "scheduler_role" {
  name = "ctf-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_ssm_policy" {
  name = "ctf-scheduler-ssm-policy"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        Resource = aws_instance.vm2_challenge.arn
      }
    ]
  })
}

# ============================================================
# EventBridge Scheduler - Dừng VM2 lúc 00:00 ICT (17:00 UTC)
# ============================================================
resource "aws_scheduler_schedule" "stop_vm2" {
  name       = "stop-vm2-nightly"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # Cron trên EventBridge dùng 6 fields (thêm field năm cuối)
  # 00:00 Asia/Ho_Chi_Minh = 17:00 UTC ngày hôm trước
  schedule_expression          = "cron(0 17 * * ? *)"
  schedule_expression_timezone = "Asia/Ho_Chi_Minh"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = [aws_instance.vm2_challenge.id]
    })
  }
}

# ============================================================
# EventBridge Scheduler - Khởi động VM2 lúc 07:30 ICT (00:30 UTC)
# ============================================================
resource "aws_scheduler_schedule" "start_vm2" {
  name       = "start-vm2-morning"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(30 0 * * ? *)"
  schedule_expression_timezone = "Asia/Ho_Chi_Minh"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      InstanceIds = [aws_instance.vm2_challenge.id]
    })
  }
}
