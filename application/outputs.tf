output "cluster_arn" {
  value       = module.ecs_cluster.cluster_arn
  description = "ARN that identifies the cluster"
}

output "cluster_name" {
  value       = module.ecs_cluster.cluster_name
  description = "Name that identifies the cluster"
}

output "service_name" {
  value       = module.ecs_service.name
  description = "Name of the service"
}
