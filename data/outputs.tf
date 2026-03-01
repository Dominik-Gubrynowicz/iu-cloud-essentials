output "db_instance_endpoint" {
  value       = module.db.db_instance_endpoint
  description = "The connection endpoint"
}

output "db_instance_name" {
  value       = module.db.db_instance_name
  description = "The database name"
}

output "db_instance_username" {
  value       = module.db.db_instance_username
  description = "The master username for the database"
  sensitive   = true
}

output "db_instance_address" {
  value       = module.db.db_instance_address
  description = "The address of the RDS instance"
}

output "db_instance_port" {
  value       = module.db.db_instance_port
  description = "The database port"
}
