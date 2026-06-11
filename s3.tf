resource "aws_s3_bucket" "estatico" {
  bucket = "s3-${var.proyecto}-${var.operacion}-01-${var.region}"
  tags   = { Name = "s3-${var.proyecto}-${var.operacion}-01-${var.region}" }
}

# Bloquear acceso publico
resource "aws_s3_bucket_public_access_block" "estatico" {
  bucket                  = aws_s3_bucket.estatico.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cifrado SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "estatico" {
  bucket = aws_s3_bucket.estatico.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# OAC - solo CloudFront puede acceder
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.proyecto}-${var.operacion}-01"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Politica del bucket - solo Cloud