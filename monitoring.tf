# ============================================================
# CloudWatch Logs y alarmas
# ============================================================

# --- LOG GROUP PARA EC2 ---
# Centraliza los logs de todas las instancias EC2
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/casino/ec2/aplicaciones"
  retention_in_days = 30  # Guarda logs por 30 dias

  tags = {
    Name = "logs-ec2-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- LOG GROUP PARA ALB ---
# Registra todos los accesos al balanceador
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/casino/alb/access"
  retention_in_days = 30

  tags = {
    Name = "logs-alb-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- LOG GROUP PARA RDS ---
# Logs de la base de datos transaccional
resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/casino/rds/mysql"
  retention_in_days = 30

  tags = {
    Name = "logs-rds-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- ALARMA ERRORES 5XX EN ALB ---
# Alerta cuando hay errores del servidor en el balanceador
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "alarma-alb-5xx-${var.proyecto}-${var.operacion}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2       # Evalua 2 periodos consecutivos
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60      # Periodo de 60 segundos
  statistic           = "Sum"
  threshold           = 10      # Alerta si hay mas de 10 errores por minuto
  alarm_description   = "Errores 5xx en el ALB superaron el umbral"

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  tags = {
    Name = "alarma-5xx-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- ALARMA ALTA LATENCIA EN ALB ---
# Alerta cuando la latencia supera 2 segundos
resource "aws_cloudwatch_metric_alarm" "alb_latencia" {
  alarm_name          = "alarma-alb-latencia-${var.proyecto}-${var.operacion}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2       # Alerta si la latencia promedio supera 2 segundos
  alarm_description   = "Latencia del ALB supero los 2 segundos"

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  tags = {
    Name = "alarma-latencia-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}