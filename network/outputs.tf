output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "List of private subnet IDs"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "List of public subnet IDs"
}

output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "The DNS name of the load balancer"
}

output "alb_arn" {
  value       = module.alb.arn
  description = "The ARN of the load balancer"
}

output "alb_listener_arn" {
  value       = module.alb.listeners["http"].arn
  description = "The ARN of the HTTP listener attached to the ALB"
}

output "alb_security_group_id" {
  value       = module.alb_sg.security_group_id
  description = "The ID of the security group attached to the ALB"
}

output "alb_target_group_arn" {
  value       = module.alb.target_groups["default"].arn
  description = "The ARN of the default target group"
}

output "alb_arn_suffix" {
  value       = module.alb.arn_suffix
  description = "The ARN suffix of the load balancer (used for CloudWatch metrics)"
}

output "alb_target_group_arn_suffix" {
  value       = module.alb.target_groups["default"].arn_suffix
  description = "The ARN suffix of the default target group (used for CloudWatch metrics)"
}

