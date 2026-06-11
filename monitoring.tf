resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/casino/ec2/aplicaciones"
  retention_in_days = 30
  tags = { Name = "logs-ec2-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/casino/alb/access"
  retention_in_days = 30
  tags = { Name = "logs-alb-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# Alarma errores 5xx en ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "alarma-alb-5xx-${var.proyecto}-${var.operacion}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  dimensions = { LoadBalancer = aws_lb.alb.arn_suffix }
}

# Alarma latencia alta
resource "aws_cloudwatch_metric_alarm" "alb_latencia" {
  alarm_name          = "alarma-alb-latencia-${var.proyecto}-${var.operacion}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  dimensions = { LoadBalancer = aws_lb.alb.arn_suffix }
}