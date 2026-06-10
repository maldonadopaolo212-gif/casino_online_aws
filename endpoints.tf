# ============================================================
#  VPC Endpoints para S3 y Secrets Manager
# Permite acceso a servicios AWS sin salir a internet
# ============================================================

# --- ENDPOINT GATEWAY PARA S3 ---
# Las instancias privadas acceden a S3 sin pasar por NAT Gateway
# Tipo Gateway = gratis, solo para S3 y DynamoDB
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_principal.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"  

  #
  route_table_ids = [aws_route_table.privada.id]

  tags = {
    Name = "endpoint-s3-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- ENDPOINT INTERFACE PARA SECRETS MANAGER ---


resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.vpc_principal.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"  # Interface crea una ENI en la subred privada

  # El endpoint vive en las subredes privadas
  subnet_ids          = [aws_subnet.privada_a.id, aws_subnet.privada_b.id]

  # Habilita DNS privado — las instancias usan el mismo endpoint DNS de siempre
  private_dns_enabled = true

  # Solo las EC2 pueden usar este endpoint
  security_group_ids  = [aws_security_group.sg_ec2.id]

  tags = {
    Name = "endpoint-secretsmanager-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}