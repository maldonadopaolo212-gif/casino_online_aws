# VPC principal - aplicaciones y APIs
resource "aws_vpc" "vpc_principal" {
  cidr_block           = var.vpc_principal_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# VPC secundaria - bodega de datos
resource "aws_vpc" "vpc_secundaria" {
  cidr_block           = var.vpc_secundaria_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id

  tags = {
    Name = "igw-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Subredes publicas
resource "aws_subnet" "publica_a" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-publica-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

resource "aws_subnet" "publica_b" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-publica-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

# Subredes privadas - EC2
resource "aws_subnet" "privada_a" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name = "subnet-privada-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

resource "aws_subnet" "privada_b" {
  vpc_id            = aws_vpc.vpc_principal.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ca-central-1b"

  tags = {
    Name = "subnet-privada-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

# Subredes VPC secundaria
resource "aws_subnet" "secundaria_privada_a" {
  vpc_id            = aws_vpc.vpc_secundaria.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name = "subnet-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

resource "aws_subnet" "secundaria_privada_b" {
  vpc_id            = aws_vpc.vpc_secundaria.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ca-central-1b"

  tags = {
    Name = "subnet-bodega-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

# EIP y NAT por AZ
resource "aws_eip" "nat_eip_a" {
  domain = "vpc"
  tags = { Name = "eip-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = { Name = "eip-${var.proyecto}-${var.operacion}-02-${var.region}" }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_eip_a.id
  subnet_id     = aws_subnet.publica_a.id
  tags = { Name = "nat-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.publica_b.id
  tags = { Name = "nat-${var.proyecto}-${var.operacion}-02-${var.region}" }
}

# Tablas de rutas
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rt-publica-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_route_table" "privada_a" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  route {
    cidr_block                = var.vpc_secundaria_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  tags = { Name = "rt-privada-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_route_table" "privada_b" {
  vpc_id = aws_vpc.vpc_principal.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  route {
    cidr_block                = var.vpc_secundaria_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
  tags = { Name = "rt-privada-${var.proyecto}-${var.operacion}-02-${var.region}" }
}

resource "aws_route_table_association" "publica_a" {
  subnet_id      = aws_subnet.publica_a.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table_association" "publica_b" {
  subnet_id      = aws_subnet.publica_b.id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table_association" "privada_a" {
  subnet_id      = aws_subnet.privada_a.id
  route_table_id = aws_route_table.privada_a.id
}

resource "aws_route_table_association" "privada_b" {
  subnet_id      = aws_subnet.privada_b.id
  route_table_id = aws_route_table.privada_b.id
}

# VPC Peering entre ambas VPCs
resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.vpc_principal.id
  peer_vpc_id = aws_vpc.vpc_secundaria.id
  auto_accept = true

  tags = {
    Name = "peering-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}