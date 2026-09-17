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
  description = "Web Server (VM1): HTTP/HTTPS only from Cloudflare (ASCII-only: AWS rejects non-ASCII SG descriptions)"
  vpc_id      = aws_vpc.ctf_vpc.id

  # Cho phép Cloudflare HTTP
  dynamic "ingress" {
    for_each = var.cloudflare_ips
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "HTTP from Cloudflare"
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
      description = "HTTPS from Cloudflare"
    }
  }

  # FRPC on VM2 initiates its encrypted control connection to FRPS on VM1.
  # Keep the listener private to this VPC; it is not a player-facing port.
  ingress {
    from_port   = 7000
    to_port     = 7000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "FRP control channel from the CTF VPC"
  }

  # Cho phép FRP challenge ports (10000-10100) cho người chơi
  ingress {
    from_port   = 10000
    to_port     = 10100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "FRP Challenge Ports"
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
# Docker API remains loopback-only and reaches VM1 through the encrypted FRP
# tunnel. VM2 therefore needs no inbound Docker or FRPC admin port.
# ============================================================

resource "aws_security_group" "sg_challenge" {
  name        = "ctf-sg-challenge"
  description = "Challenge Server (VM2): private Docker API via FRP tunnel"
  vpc_id      = aws_vpc.ctf_vpc.id

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
  description = "RDS PostgreSQL: connections only from VM1 Web Server (ASCII-only: AWS rejects non-ASCII SG descriptions)"
  vpc_id      = aws_vpc.ctf_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_web.id]
    description     = "PostgreSQL from VM1 Web Server"
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
