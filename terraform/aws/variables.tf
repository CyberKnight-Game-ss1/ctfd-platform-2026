variable "aws_region" {
  description = "AWS region để triển khai tất cả resources"
  type        = string
  default     = "ap-southeast-1" # Singapore - latency tốt cho SEA/VN
}

variable "vpc_cidr" {
  description = "CIDR block cho AWS VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_public_1_cidr" {
  description = "CIDR block cho Public Subnet 1 (AZ-a) - dùng cho VM1, VM2"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_public_2_cidr" {
  description = "CIDR block cho Public Subnet 2 (AZ-b) - bắt buộc cho RDS Subnet Group"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cloudflare_ips" {
  description = "Cloudflare IPv4 ranges (dùng để giới hạn traffic HTTP/HTTPS vào VM1)"
  type        = list(string)
  default     = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
    "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
    "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
    "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22"
  ]
}

variable "db_password" {
  description = "Password cho user 'ctfd' trên RDS PostgreSQL"
  type        = string
  sensitive   = true
}

variable "ctf_domain" {
  description = "Tên miền của cuộc thi CTF (ví dụ: cyberknightgame.site)"
  type        = string
}

variable "is_practice_mode" {
  description = "Set true để dùng EC2 Spot Instance cho VM2 (tiết kiệm ~70% chi phí khi luyện tập)"
  type        = bool
  default     = true
}

variable "vm1_instance_type" {
  description = "EC2 instance type cho VM1 (Web Server)"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4 GB RAM
}

variable "vm2_instance_type" {
  description = "EC2 instance type cho VM2 (Challenge Server)"
  type        = string
  default     = "t3.large" # 2 vCPU, 8 GB RAM
}

variable "db_instance_class" {
  description = "RDS instance class cho PostgreSQL"
  type        = string
  default     = "db.t3.micro" # Đủ dùng cho CTF quy mô nhỏ-vừa
}
