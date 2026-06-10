# ============================================================
# RDS para bodega de datos historica
# VPC Secundaria


# Subnet group de RDS en VPC secundaria
resource "aws_db_subnet_group" "bodega" {
  name       = "rds-subnet-bodega-${var.proyecto}-${var.operacion}-01"
  subnet_ids = [
    aws_subnet.secundaria_privada_a.id,
    aws_subnet.secundaria_privada_b.id
  ]

  tags = {
    Name = "rds-subnet-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Security Group para RDS bodega
# Solo acepta trafico desde VPC principal via peering
resource "aws_security_group" "sg_rds_bodega" {
  name        = "sg-rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "Security group RDS bodega historica"
  vpc_id      = aws_vpc.vpc_secundaria.id

  ingress {
    description = "MySQL solo desde VPC principal via peering"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_principal_cidr]
  }

  egress {
    description = "Todo trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# RDS MySQL — bodega de datos historica
resource "aws_db_instance" "rds_bodega" {
  identifier           = "rds-bodega-${var.proyecto}-${var.operacion}-01"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.medium"
  allocated_storage    = 100           # Mas almacenamiento para datos historicos
  username             = "admin"
  password             = "Changeme123!"  # TODO: mover a Secrets Manager
  db_subnet_group_name = aws_db_subnet_group.bodega.name
  vpc_security_group_ids = [aws_security_group.sg_rds_bodega.id]
  multi_az             = false         # Bodega historica no requiere Multi-AZ
  skip_final_snapshot  = true
  publicly_accessible  = false

  tags = {
    Name = "rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}