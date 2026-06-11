# Endpoint S3 tipo Gateway - gratis, sin salir a internet
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_principal.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.privada_a.id, aws_route_table.privada_b.id]
  tags = { Name = "endpoint-s3-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# Endpoint Secrets Manager tipo Interface
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.vpc_principal.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.privada_a.id, aws_subnet.privada_b.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.sg_ec2.id]
  tags = { Name = "endpoint-secretsmanager-${var.proyecto}-${var.operacion}-01-${var.region}" }
}