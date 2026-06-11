output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket" {
  value = aws_s3_bucket.estatico.bucket
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "rds_endpoint" {
  value = aws_db_instance.rds_principal.endpoint
}

output "redshift_endpoint" {
  value = aws_db_instance.rds_bodega.endpoint
}