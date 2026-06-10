# ==============================================================================
# 1. CORE MANDATORY OUTPUTS
# ==============================================================================

output "cluster_endpoint" {
  description = "The endpoint URL for your Amazon EKS Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The precise name of the running Amazon EKS cluster."
  value       = module.eks.cluster_name
}

output "region" {
  description = "The AWS Region targeted for this deployment infrastructure."
  value       = "us-east-1"
}

output "vpc_id" {
  description = "The unique identifier assigned to the created project VPC."
  value       = module.vpc.vpc_id
}

output "assets_bucket_name" {
  description = "The unique identifier name of the generated marketing assets S3 bucket."
  value       = aws_s3_bucket.assets.id
}

# ==============================================================================
# 2. DATA LAYER CONNECTIONS
# ==============================================================================

output "mysql_endpoint" {
  description = "The connection address string for your managed Amazon RDS MySQL database."
  value       = aws_db_instance.mysql.endpoint
}

output "mysql_database_name" {
  description = "The default internal schema name initialized for the Catalog microservice."
  value       = aws_db_instance.mysql.db_name
}

output "postgres_endpoint" {
  description = "The connection address string for your managed Amazon RDS PostgreSQL database."
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_database_name" {
  description = "The default internal schema name initialized for the Orders microservice."
  value       = aws_db_instance.postgres.db_name
}

output "dynamodb_table_name" {
  description = "The specific identifier assigned to your tracking table within DynamoDB."
  value       = aws_dynamodb_table.carts.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table for setting up IAM permissions later"
  value       = aws_dynamodb_table.carts.arn
}