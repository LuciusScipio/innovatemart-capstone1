variable "db_username" {
  type        = string
  description = "The master username for the RDS database instances"
}

variable "db_password" {
  type        = string
  description = "The master password for the RDS database instances"
  sensitive   = true
}