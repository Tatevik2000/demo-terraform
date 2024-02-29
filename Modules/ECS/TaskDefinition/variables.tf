 variable "docker_image_url" {  
  type        = string  
  description = "URL of the Docker image to use in the task definition."  
}  
  
variable "container_cpu" {  
  type        = number  
  description = "The number of CPU units to allocate for the container."  
}  
  
variable "container_memory" {  
  type        = number  
  description = "The amount of memory (in MiB) to allocate for the container."  
}  
  
variable "aws_region" {  
  type        = string  
  description = "The AWS region where resources will be created."  
}  

variable "name" {
  description = "The name for Task Definition"
  type        = string
}

variable "container_name" {
  description = "The name of the Container specified in the Task definition"
  type        = string
}

variable "execution_role_arn" {
  description = "The IAM ARN role that the ECS task will use to call other AWS services"
  type        = string
}

variable "task_role_arn" {
  description = "The IAM ARN role that the ECS task will use to call other AWS services"
  type        = string
  default     = null
}

variable "cpu" {
  description = "The CPU value to assign to the container, read AWS documentation for available values"
  type        = string
}

variable "memory" {
  description = "The MEMORY value to assign to the container, read AWS documentation to available values"
  type        = string
}

variable "docker_repo" {
  description = "The docker registry URL in which ecs will get the Docker image"
  type        = string
}

variable "region" {
  description = "AWS Region in which the resources will be deployed"
  type        = string
}

variable "container_port" {
  description = "The port that the container will use to listen to requests"
  type        = number
}
