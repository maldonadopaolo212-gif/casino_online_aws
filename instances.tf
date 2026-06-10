# ============================================================
# EC2, ALB, Security Groups y ElastiCache
# ============================================================

# --- AMI MAS RECIENTE DE AMAZON LINUX ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- SECURITY GROUP DEL ALB ---
# Solo acepta trafico HTTPS desde internet
resource "aws_security_group" "sg_alb" {
  name        = "sg-alb-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "Security group del Application Load Balancer"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description = "HTTPS desde internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP redirige a HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-alb-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- SECURITY GROUP DE LAS EC2 ---
# Solo acepta trafico del ALB, no desde internet directamente
resource "aws_security_group" "sg_ec2" {
  name        = "sg-ec2-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "Security group de las instancias EC2"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description     = "Trafico desde el ALB unicamente"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  egress {
    description = "Todo trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-ec2-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- SECURITY GROUP DE REDIS ---
# Solo acepta trafico desde las EC2
resource "aws_security_group" "sg_redis" {
  name        = "sg-redis-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "Security group de ElastiCache Redis"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description     = "Redis solo accesible desde EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ec2.id]
  }

  egress {
    description = "Todo trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-redis-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- SECURITY GROUP DE RDS ---
# Solo acepta trafico desde las EC2
resource "aws_security_group" "sg_rds" {
  name        = "sg-rds-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "Security group de RDS"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description     = "MySQL solo accesible desde EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ec2.id]
  }

  egress {
    description = "Todo trafico saliente permitido"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-rds-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- INSTANCIAS EC2 ---
# Frontsite — interfaz publica del casino
resource "aws_instance" "frontsite" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_a.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  tags = {
    Name = "ec2-frontsite-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Backoffice — panel de administracion
resource "aws_instance" "backoffice" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_b.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  tags = {
    Name = "ec2-backoffice-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# WebAPI — API principal del negocio
resource "aws_instance" "webapi" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_a.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  tags = {
    Name = "ec2-webapi-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# GameAPI — API de los juegos del casino
resource "aws_instance" "gameapi" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_b.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  tags = {
    Name = "ec2-gameapi-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- APPLICATION LOAD BALANCER ---
# Recibe trafico de internet y lo distribuye a las EC2 privadas
resource "aws_lb" "alb" {
  name               = "alb-${var.proyecto}-${var.operacion}-01"
  internal           = false  # Publico — acepta trafico desde internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.publica_a.id, aws_subnet.publica_b.id]

  tags = {
    Name = "alb-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# Target group — define a donde envia el trafico el ALB
resource "aws_lb_target_group" "tg" {
  name     = "tg-${var.proyecto}-${var.operacion}-01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_principal.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Listener HTTPS — recibe trafico en puerto 443
# TODO: agregar certificado ACM real antes de produccion
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ca-central-1:123456789:certificate/placeholder"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# --- ELASTICACHE REDIS ---
# Capa de cache para reducir carga en RDS y mejorar latencia
resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "redis-subnet-${var.proyecto}-${var.operacion}-01"
  subnet_ids = [aws_subnet.privada_a.id, aws_subnet.privada_b.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-${var.proyecto}-${var.operacion}-01"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.name
  security_group_ids   = [aws_security_group.sg_redis.id]

  tags = {
    Name = "redis-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- RDS MYSQL ---
# Base de datos transaccional principal
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-${var.proyecto}-${var.operacion}-01"
  subnet_ids = [aws_subnet.privada_a.id, aws_subnet.privada_b.id]

  tags = {
    Name = "rds-subnet-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

resource "aws_db_instance" "rds_principal" {
  identifier           = "rds-${var.proyecto}-${var.operacion}-01"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  username             = "admin"
  password             = "Test1Prueba!"  # TODO: mover a Secrets Manager
  db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  multi_az             = true   # Alta disponibilidad — failover automatico
  skip_final_snapshot  = true

  tags = {
    Name = "rds-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}