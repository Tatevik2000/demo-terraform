output "arn_alb" {  
  value = var.create_alb ? aws_alb.alb[0].arn : null  
}  
  
output "arn_tg_1" {  
  value = var.create_target_group_1 ? aws_alb_target_group.target_group_1[0].arn : null  
}  
  
output "arn_tg_2" {  
  value = var.create_target_group_2 ? aws_alb_target_group.target_group_2[0].arn : null  
}  
  
output "tg_name_1" {  
  value = var.create_target_group_1 ? aws_alb_target_group.target_group_1[0].name : null  
}  
  
output "tg_name_2" {  
  value = var.create_target_group_2 ? aws_alb_target_group.target_group_2[0].name : null  
}  
  
output "arn_listener_http" {  
  value = var.create_alb ? aws_alb_listener.http_listener[0].arn : null  
}  
  
output "arn_listener_https" {  
  value = var.create_alb && var.enable_https ? aws_alb_listener.https_listener[0].arn : null  
}  
  
output "dns_alb" {  
  value = var.create_alb ? aws_alb.alb[0].dns_name : null  
}  

