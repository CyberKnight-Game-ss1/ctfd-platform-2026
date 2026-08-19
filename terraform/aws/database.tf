# ============================================================
# RDS Subnet Group - bắt buộc phải có ít nhất 2 AZ
# ============================================================
resource "aws_db_subnet_group" "ctf_db_subnet_group" {
  name       = "ctf-db-subnet-group"
  subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name    = "ctf-db-subnet-group"
    Project = "CyberKnight-CTF"
  }
}

# ============================================================
# RDS PostgreSQL 15
# - Không có public access (chỉ truy cập từ VM1 qua sg_db)
# - Bật backup tự động 7 ngày
# - Bật encryption at rest
# - Dùng db.t3.micro cho luyện tập; nâng lên db.t3.medium khi thi đấu thật
# ============================================================
resource "aws_db_instance" "ctf_postgres" {
  identifier        = "ctf-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20     # GB
  storage_type      = "gp3"
  storage_encrypted = true   # Mã hóa dữ liệu lưu trữ

  db_name  = "ctfd"
  username = "ctfd"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.ctf_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_db.id]

  publicly_accessible     = false  # Không expose public IP cho DB
  skip_final_snapshot     = true   # Đổi thành false khi thi đấu thật
  deletion_protection     = false  # Đổi thành true khi thi đấu thật

  backup_retention_period = 7      # Giữ backup trong 7 ngày
  backup_window           = "19:00-20:00"   # 02:00 - 03:00 ICT (UTC+7)
  maintenance_window      = "Mon:20:00-Mon:21:00"

  tags = {
    Name    = "ctf-postgres"
    Project = "CyberKnight-CTF"
  }
}

# ============================================================
# SSM Parameter Store - lưu DATABASE_URL
# Dùng SecureString (miễn phí, mã hóa bằng KMS mặc định của AWS)
# VM1 sẽ đọc tham số này qua AWS CLI lúc startup
# ============================================================
resource "aws_ssm_parameter" "db_url" {
  name  = "/ctfd/database-url"
  type  = "SecureString"
  value = "postgresql://ctfd:${var.db_password}@${aws_db_instance.ctf_postgres.endpoint}/ctfd"

  tags = {
    Project = "CyberKnight-CTF"
  }
}
