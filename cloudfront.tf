resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.estatico.bucket_regional_domain_name
    origin_id                = "s3-${var.proyecto}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${var.proyecto}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  # TODO: agregar certificado propio con dominio real
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "cdn-${var.proyecto}-${var.operacion}-01-${var.region}" }
}