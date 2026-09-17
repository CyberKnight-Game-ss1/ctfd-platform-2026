# ============================================================
# IAM Role - gắn cho EC2 instances để gọi AWS services
# Policies:
#   - AmazonSSMManagedInstanceCore: Cho phép SSM Session Manager (SSH không cần port 22)
#   - CloudWatchAgentServerPolicy: Cho phép ghi logs lên CloudWatch
#   - AmazonSSMReadOnlyAccess: Cho phép đọc secrets từ SSM Parameter Store
# ============================================================

resource "aws_iam_role" "ctf_vm_role" {
  name = "ctf-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "ctf-vm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ctf_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ctf_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_readonly" {
  role       = aws_iam_role.ctf_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ctf_vm_profile" {
  name = "ctf-vm-profile"
  role = aws_iam_role.ctf_vm_role.name
}

# ============================================================
# AMI Data Source - lấy Ubuntu 22.04 LTS mới nhất trên AWS
# ============================================================

data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu official)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# VM1 - Web Server (CTFd + Redis + Nginx)
# instance type mặc định: t3.small (2 vCPU, 2 GB RAM) — luyện tập; nếu OOM thì giảm WORKERS hoặc nâng type
#
# QUAN TRỌNG - Bảo mật IMDSv2:
#   http_tokens = "required" bắt buộc dùng IMDSv2 thay vì IMDSv1
#   http_put_response_hop_limit = 1 chặn container bên trong EC2
#   đọc metadata (chống SSRF từ Web Challenge leo thang lấy IAM token)
# ============================================================

resource "aws_instance" "vm1_web" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.vm1_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ctf_vm_profile.name

  root_block_device {
    volume_size = 30 # GB
    volume_type = "gp3"
    encrypted   = true
  }

  # Bật IMDSv2 - BẮT BUỘC trong môi trường CTF có Web Exploitation challenge
  # Ngăn SSRF khai thác metadata endpoint để đánh cắp IAM credentials
  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1          # Không cho container bên trong đọc metadata
    http_endpoint               = "enabled"
  }

  tags = {
    Name    = "ctf-vm1-web"
    Role    = "web-server"
    Project = "CyberKnight-CTF"
  }
}

# ============================================================
# Elastic IP cho VM1 (Web Server)
# Lý do: không có EIP, mỗi lần stop/start VM1 (bảo trì, resize) public IP sẽ ĐỔI
#   -> A record cyberknightgame.site trên Cloudflare trỏ sai cho tới khi sửa tay.
# Chi phí: AWS tính $0.005/giờ (~$3.65/tháng) cho MỌI public IPv4 gắn vào instance
#   đang chạy, kể cả IP động tự cấp -> EIP gần như TRUNG TÍNH chi phí mà cố định DNS.
# LƯU Ý: KHÔNG gắn EIP cho VM2 — VM2 stop 7.5h/đêm, EIP gắn vào instance stopped
#   vẫn bị tính phí -> thêm ~$3.65/tháng vô ích.
# Khi associate EIP, AWS tự thu hồi IP động mà instance nhận lúc launch.
# ============================================================

resource "aws_eip" "vm1_web" {
  domain   = "vpc"
  instance = aws_instance.vm1_web.id

  tags = {
    Name    = "ctf-vm1-web-eip"
    Project = "CyberKnight-CTF"
  }
}

# ============================================================
# VM2 - Challenge Server (Docker + K3s + CTFd Whale)
# instance type mặc định: m7i-flex.large (2 vCPU, 8 GB RAM, x86_64)
#   -> t3.large KHÔNG dùng được vì account đang ở AWS Free plan (chỉ cho free-tier-eligible type)
# Dùng Spot Instance khi is_practice_mode = true (tiết kiệm ~60-70%)
# ============================================================

resource "aws_instance" "vm2_challenge" {
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.vm2_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.sg_challenge.id]
  iam_instance_profile   = aws_iam_instance_profile.ctf_vm_profile.name

  root_block_device {
    volume_size = 50 # GB - cần nhiều dung lượng cho Docker images của challenges
    volume_type = "gp3"
    encrypted   = true
  }

  # Bật IMDSv2
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  # Dùng Spot Instance để tiết kiệm chi phí khi ở chế độ luyện tập
  # LƯU Ý: `instance_interruption_behavior = "stop"` CHỈ hợp lệ với Spot request `persistent`
  # (AWS trả lỗi: "The request with type 'one-time' is not supported when instanceInterruptionBehavior is set to 'STOP'").
  # persistent + stop = khi AWS thu hồi capacity, instance chỉ STOP, EBS giữ nguyên, EC2 tự start lại khi có capacity.
  # EventBridge stop ban đêm vẫn hoạt động vì "chỉ Amazon EC2 mới restart được instance bị stop do interruption"
  # (user-initiated stop giữ nguyên trạng thái stopped).
  dynamic "instance_market_options" {
    for_each = var.is_practice_mode ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        spot_instance_type             = "persistent"
        instance_interruption_behavior = "stop"
      }
    }
  }

  tags = {
    Name    = "ctf-vm2-challenge"
    Role    = "challenge-server"
    Project = "CyberKnight-CTF"
  }
}
