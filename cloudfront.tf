# ============================================================
# CDN para contenido estatico del casino
# ============================================================

# --- DISTRIBUCION CLOUDFRONT ---
# Sirve el contenido de S3 globalmente con baja latencia
resource "aws_cloudfront_distribution" "cdn" {

  # Origen — de donde CloudFront obtiene el contenido
  origin {
    domain_name              = aws_s3_bucket.estatico.bucket_regional_domain_name
    origin_id                = "s3-origin-${var.proyecto}"

    # Usa OAC para autenticarse con S3 de forma segura
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true   # Distribucion activa
  is_ipv6_enabled     = true   # Soporte IPv6
  comment             = "CDN Casino Online Promarketing"
  default_root_object = "index.html"  # Archivo raiz por defecto

  # Comportamiento del cache por defecto
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]  # Solo lectura — contenido estatico
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin-${var.proyecto}"
    viewer_protocol_policy = "redirect-to-https"  # Fuerza HTTPS siempre

    # Configuracion de cache
    forwarded_values {
      query_string = false  # No cachea por query string
      cookies {
        forward = "none"  # No reenvía cookies al origen
      }
    }

    min_ttl     = 0      # Tiempo minimo en cache (segundos)
    default_ttl = 3600   # Cache por defecto 1 hora
    max_ttl     = 86400  # Cache maximo 24 horas
  }

  # Restricciones geograficas
  # TODO: evaluar si restringir a Chile y Canada solamente
  restrictions {
    geo_restriction {
      restriction_type = "none"  # Sin restricciones geograficas por ahora
    }
  }

  # Certificado SSL — usa el certificado por defecto de CloudFront
  # TODO: agregar certificado ACM propio con dominio real
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "cdn-${var.proyecto}-${var.operacion}-01-${var.region}"
  }
}