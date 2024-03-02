output "arn_alb" {  
  description = "ARN of the Application Load Balancer"  
  value       = var.create_alb ? aws_alb.alb[0].arn : null  
}  
  
output "arn_tg" {  
  description = "ARN of the Target Group"  
  value       = var.create_target_group ? aws_alb_target_group.target_group[0].arn : null  
}  
  
output "tg_name" {  
  description = "Name of the Target Group"  
  value       = var.create_target_group ? aws_alb_target_group.target_group[0].name : null  
}  
  
output "arn_listener" {  
  description = "ARN of the ALB HTTP Listener"  
  value       = var.create_alb ? aws_alb_listener.http_listener[0].arn : null  
}  
  
output "dns_alb" {  
  description = "DNS Name of the Application Load Balancer"  
  value       = var.create_alb ? aws_alb.alb[0].dns_name : null  
}  
