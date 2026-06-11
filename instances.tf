# AMI Amazon Linux 2023 - busca la mas reciente automaticamente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# SG del ALB - solo acepta HTTPS y HTTP
resource "aws_security_group" "sg_alb" {
  name        = "sg-alb-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "SG Application Load Balancer"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-alb-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# SG EC2 - solo acepta trafico desde el ALB
resource "aws_security_group" "sg_ec2" {
  name        = "sg-ec2-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "SG instancias EC2"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-ec2-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# SG Redis - solo desde EC2
resource "aws_security_group" "sg_redis" {
  name        = "sg-redis-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "SG ElastiCache Redis"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-redis-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# SG RDS - solo desde EC2
resource "aws_security_group" "sg_rds" {
  name        = "sg-rds-${var.proyecto}-${var.operacion}-01-${var.region}"
  description = "SG RDS MySQL"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-rds-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# EC2s en subredes privadas
resource "aws_instance" "frontsite" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_a.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  tags = { Name = "ec2-frontsite-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_instance" "backoffice" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_b.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  tags = { Name = "ec2-backoffice-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_instance" "webapi" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_a.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  tags = { Name = "ec2-webapi-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_instance" "gameapi" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.privada_b.id
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  tags = { Name = "ec2-gameapi-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# ALB
resource "aws_lb" "alb" {
  name               = "alb-${var.proyecto}-${var.operacion}-01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.publica_a.id, aws_subnet.publica_b.id]
  tags = { Name = "alb-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

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

# Listener HTTPS - necesita certificado ACM real
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ca-central-1:123456789012:certificate/placeholder"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ElastiCache Redis
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
  tags = { Name = "redis-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# RDS MySQL - transaccional
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-${var.proyecto}-${var.operacion}-01"
  subnet_ids = [aws_subnet.privada_a.id, aws_subnet.privada_b.id]
  tags = { Name = "rds-subnet-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_db_instance" "rds_principal" {
  identifier             = "rds-${var.proyecto}-${var.operacion}-01"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  username               = "admin"
  password               = "Changeme123!"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  multi_az               = true
  skip_final_snapshot    = true
  tags = { Name = "rds-${var.proyecto}-${var.operacion}-01-${var.region}" }
}