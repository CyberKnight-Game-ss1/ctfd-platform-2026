# ============================================================
# VPC và Internet Gateway
# ============================================================

resource "aws_vpc" "ctf_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "ctf-vpc"
    Project = "CyberKnight-CTF"
  }
}

resource "aws_internet_gateway" "ctf_igw" {
  vpc_id = aws_vpc.ctf_vpc.id

  tags = {
    Name = "ctf-igw"
  }
}

# ============================================================
# Public Subnets (cần ít nhất 2 AZ khác nhau để tạo RDS Subnet Group)
# ============================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.ctf_vpc.id
  cidr_block              = var.subnet_public_1_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ctf-subnet-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.ctf_vpc.id
  cidr_block              = var.subnet_public_2_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ctf-subnet-public-2"
  }
}

# ============================================================
# Route Table - định tuyến traffic ra internet qua IGW
# ============================================================

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ctf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ctf_igw.id
  }

  tags = {
    Name = "ctf-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ============================================================
# Security Group: VM1 - Web Server
# Chỉ cho phép HTTP/HTTPS từ Cloudflare IP ranges
# ============================================================

resource "aws_security_group" "sg_web" {
  name        = "ctf-sg-web"
  description = "Web Server (VM1): chỉ cho phép HTTP/HTTPS từ Cloudflare"
  vpc_id      = aws_vpc.ctf_vpc.id

  # Cho phép Cloudflare HTTP
  dynamic "ingress" {
    for_each = var.cloudflare_ips
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "HTTP từ Cloudflare"
    }
  }

  # Cho phép Cloudflare HTTPS
  dynamic "ingress" {
    for_each = var.cloudflare_ips
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "HTTPS từ Cloudflare"
    }
  }

  # Cho phép mọi traffic ra ngoài
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "ctf-sg-web"
  }
}

# ============================================================
# Security Group: VM2 - Challenge Server
# Chỉ nhận Docker mTLS (2376) từ VM1, không expose ra internet
# ============================================================

resource "aws_security_group" "sg_challenge" {
  name        = "ctf-sg-challenge"
  description = "Challenge Server (VM2): Docker mTLS chỉ nhận từ VM1 sg_web"
  vpc_id      = aws_vpc.ctf_vpc.id

  # Chỉ cho phép Docker mTLS từ VM1 (thông qua Security Group reference)
  ingress {
    from_port       = 2376
    to_port         = 2376
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
    description     = "Docker mTLS từ VM1 Web Server"
  }

  # Cho phép mọi traffic ra ngoài (Docker cần kéo images từ internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "ctf-sg-challenge"
  }
}

# ============================================================
# Security Group: RDS - Database
# Chỉ nhận PostgreSQL (5432) từ VM1
# ============================================================

resource "aws_security_group" "sg_db" {
  name        = "ctf-sg-db"
  description = "RDS PostgreSQL: chỉ nhận kết nối từ VM1 Web Server"
  vpc_id      = aws_vpc.ctf_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
    description     = "PostgreSQL từ VM1 Web Server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "ctf-sg-db"
  }
}
