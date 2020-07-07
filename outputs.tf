output "endpoint" {
  description = "The DNS address of the RDS instance"
  value       = aws_rds_cluster.cluster.endpoint
}

output "reader_endpoint" {
  description = "A read-only endpoint for the Aurora cluster, automatically load-balanced across replicas."
  value       = aws_rds_cluster.cluster.reader_endpoint
}
