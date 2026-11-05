terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# 1. La VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Internet Gateway (Acceso a internet para la red)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3. Subred Pública (Para balanceadores o recursos expuestos)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-subnet-public"
  }
}

# 4. Subred Privada (Para bases de datos o servidores internos seguros)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-subnet-private"
  }
}
# ==========================================
# 5. CONFIGURACIÓN DE LA RED PÚBLICA
# ==========================================

# Tabla de ruteo para la subred pública (Ruta hacia el Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Todo el tráfico exterior
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# Asociamos la tabla de ruteo con nuestra subred pública
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# 6. CONFIGURACIÓN DE LA RED PRIVADA Y NAT GATEWAY
# ==========================================

# Necesitamos una IP elástica (IP pública fija) para el NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.project_name}-eip-nat"
  }
}

# El NAT Gateway (Se coloca en la subred pública para dar salida a la privada)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  # Buena práctica: Asegura que el IGW se cree antes que el NAT
  depends_on = [aws_internet_gateway.gw]
}

# Tabla de ruteo para la subred privada (Ruta hacia el NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-rt-private"
  }
}

# Asociamos la tabla de ruteo con nuestra subred privada
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}