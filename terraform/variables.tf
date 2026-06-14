variable "db_username" {
  type        = string
  description = "Master username for RDS databases"
}

variable "db_password" {
  type        = string
  description = "Master password for RDS databases"
  sensitive   = true # This hides the password from showing up in plain text in your GitHub logs
}