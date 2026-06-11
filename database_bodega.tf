resource "aws_db_subnet_group" "bodega" {
  name       = "rds-subnet-bodega-${var.proyecto}-${var.operacion}-01"
  subnet_ids = [aws_subnet.secundaria_privada_a.id, aws_subnet.secundaria_privada_b.id]
  tags = { Name = "rds-subnet-bodega-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_security_group" "sg_rds_bodega" {
  name        = "sg-rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "SG RDS bodega historica"
  vpc_id      = aws_vpc.vpc_secundaria.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_principal_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_db_instance" "rds_bodega" {
  identifier             = "rds-bodega-${var.proyecto}-${var.operacion}-01"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.medium"
  allocated_storage      = 100
  username               = "admin"
  password               = "Changeme123!"
  db_subnet_group_name   = aws_db_subnet_group.bodega.name
  vpc_security_group_ids = [aws_security_group.sg_rds_bodega.id]
  multi_az               = false
  skip_final_snapshot    = true
  publicly_accessible    = false
  tags = { Name = "rds-bodega-${var.proyecto}-${var.operacion}-01-${var.region}" }
}