variable "create_target_group_2" {  
  description = "Whether to create a second target group"  
  type        = bool  
  default     = false  
}    
  
 
  
variable "tg_type_2" {  
  description = "Type of target that you must specify when registering targets with this target group"  
  type        = string  
  default     = "instance" # or "ip" or "lambda", based on your use case  
}  
  
variable "deregistration_delay" {  
  description = "Amount of time to wait before changing the state of a deregistering target from draining to unused"  
  type        = number  
  default     = 300 # default is 300 seconds  
}  
  
# Health check related variables for the second target group  
  
variable "health_check_enabled" {  
  description = "Indicates whether health checks are enabled for the second target group"  
  type        = bool  
  default     = true  
}  
  
variable "health_check_interval" {  
  description = "Approximate amount of time, in seconds, between health checks of an individual target for the second target group"  
  type        = number  
  default     = 30  
}   
  
variable "health_check_timeout" {  
  description = "Amount of time, in seconds, during which no response means a failed health check for the second target group"  
  type        = number  
  default     = 5  
}  
  
variable "healthy_threshold" {  
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy for the second target group"  
  type        = number  
  default     = 3  
}  
  
variable "unhealthy_threshold" {  
  description = "Number of consecutive health check failures required before considering the target unhealthy for the second target group"  
  type        = number  
  default     = 3  
}  
  
variable "health_check_matcher" {  
  description = "HTTP codes to use when checking for a successful response from a target for the second target group's health checks"  
  type        = string  
  default     = "200"  
}  


variable "name" {
  description = "A name for the target group or ALB"
  type        = string
}

variable "target_group" {
  description = "The ARN of the created target group"
  type        = string
  default     = ""
}

variable "target_group_green" {
  description = "The ANR of the created target group"
  type        = string
  default     = ""
}

variable "create_alb" {
  description = "Set to true to create an ALB"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Set to true to create a HTTPS listener"
  type        = bool
  default     = false
}

variable "create_target_group" {
  description = "Set to true to create a Target Group"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Subnets IDs for ALB"
  type        = list(any)
  default     = []
}

variable "security_group" {
  description = "Security group ID for the ALB"
  type        = string
  default     = ""
}

variable "port" {
  description = "The port that the targer group will use"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "The protocol that the target group will use"
  type        = string
  default     = ""
}

variable "vpc" {
  description = "VPC ID for the Target Group"
  type        = string
  default     = ""
}

variable "tg_type" {
  description = "Target Group Type (instance, IP, lambda)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "The path in which the ALB will send health checks"
  type        = string
  default     = ""
}

variable "health_check_port" {
  description = "The port to which the ALB will send health checks"
  type        = number
  default     = 80
}
