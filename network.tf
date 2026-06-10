# ============================================================
# VPCs, Subredes, Gateways y VPC Peering
# ============================================================

# --- VPC PRINCIPAL ---
# Aqui viven las aplicaciones, frontend y APIs
resource "aws_vpc" "vpc_principal" {
  cidr_block           = var.vpc_principal_cidr
  enable_dns_hostnames = true  # Necesario para que las instancias tengan DNS
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- VPC SECUNDARIA ---
# Aqui vive la bodega de datos historica
resource "aws_vpc" "vpc_secundaria" {
  cidr_block           = var.vpc_secundaria_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

# --- INTERNET GATEWAY ---
# Permite trafico publico entrante y saliente en VPC principal
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id

  tags = {
    Name = "igw-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- SUBREDES PUBLICAS (VPC Principal) ---
# Zona de disponibilidad A
resource "aws_subnet" "publica_a" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true  # Las instancias aqui obtienen IP publica

  tags = {
    Name = "subnet-publica-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Zona de disponibilidad B
resource "aws_subnet" "publica_b" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-publica-${var.proyecto}-${var.operacion}-02-${var.region}"
  }
}

# --- SUBREDES PRIVADAS (VPC Principal) ---
# Las EC2 y RDS viven aqui, sin IP publica
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

# --- SUBREDES VPC SECUNDARIA ---
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

# --- ELASTIC IP para NAT Gateway ---
# IP fija que se asigna al NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "eip-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- NAT GATEWAY ---
# Permite que las instancias privadas salgan a internet
# pero no reciben trafico entrante desde internet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.publica_a.id  # El NAT vive en subred publica

  tags = {
    Name = "nat-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- TABLAS DE ENRUTAMIENTO ---

# Tabla publica — enruta trafico a internet via IGW
resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-publica-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Tabla privada — enruta trafico a internet via NAT Gateway
resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rt-privada-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- ASOCIACIONES DE TABLAS ---
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
  route_table_id = aws_route_table.privada.id
}

resource "aws_route_table_association" "privada_b" {
  subnet_id      = aws_subnet.privada_b.id
  route_table_id = aws_route_table.privada.id
}

# --- VPC PEERING ---
# Conecta VPC principal con VPC secundaria (bodega de datos)
resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.vpc_principal.id
  peer_vpc_id = aws_vpc.vpc_secundaria.id
  auto_accept = true  # Acepta automaticamente porque ambas VPCs son de la misma cuenta

  tags = {
    Name = "peering-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Ruta en VPC principal hacia VPC secundaria via peering
resource "aws_route" "principal_a_secundaria" {
  route_table_id            = aws_route_table.privada.id
  destination_cidr_block    = var.vpc_secundaria_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}