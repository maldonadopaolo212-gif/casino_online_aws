# ============================================================
# Bucket S3 privado para contenido estatico
# ============================================================

# --- BUCKET S3 ---
# Almacena imagenes, assets y archivos estaticos del casino
resource "aws_s3_bucket" "estatico" {
  bucket = "s3-${var.proyecto}-${var.operacion}-01-${var.region}"

  tags = {
    Name = "s3-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}

# --- BLOQUEAR ACCESO PUBLICO ---
# El bucket NO es publico — solo CloudFront puede acceder
resource "aws_s3_bucket_public_access_block" "estatico" {
  bucket = aws_s3_bucket.estatico.id

  block_public_acls       = true  # Bloquea ACLs publicas
  block_public_policy     = true  # Bloquea politicas publicas
  ignore_public_acls      = true  # Ignora ACLs publicas existentes
  restrict_public_buckets = true  # Restringe acceso anonimo
}

# --- CIFRADO DEL BUCKET ---
# Los archivos se guardan cifrados con SSE-S3
resource "aws_s3_bucket_server_side_encryption_configuration" "estatico" {
  bucket = aws_s3_bucket.estatico.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Cifrado SSE-S3 estandar
    }
  }
}

# --- ORIGIN ACCESS CONTROL (OAC) ---
# Permite que solo CloudFront acceda al bucket
# OAC es la version moderna y recomendada del OAI
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.proyecto}-${var.operacion}-01"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"  # Siempre firma las solicitudes
  signing_protocol                  = "sigv4"   # Protocolo de firma AWS
}

# --- POLITICA DEL BUCKET ---
# Solo permite acceso desde CloudFront via OAC
resource "aws_s3_bucket_policy" "estatico" {
  bucket = aws_s3_bucket.estatico.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.estatico.arn}/*"
        Condition = {
          StringEquals = {
            # Solo permite acceso desde esta distribucion CloudFront
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}