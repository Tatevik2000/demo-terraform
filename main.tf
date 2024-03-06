resource "random_id" "RANDOM_ID" {
  byte_length = "2"
}

# ------- Account ID -------
data "aws_caller_identity" "id_current_account" {}

# ------- vpc -------
module "vpc" {
  source = "./Modules/vpc"
  cidr   = ["10.120.0.0/16"]
  name   = var.environment_name
}  
  
# Define the ALB  
resource "aws_lb" "alb" {  
  name               = "alb-demo"  
  internal           = false  
  load_balancer_type = "application"  
  security_groups    = [aws_security_group.alb_sg.id]  
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]  
  
  enable_deletion_protection = false  
}  
/*
# Create the first target group for general traffic  
resource "aws_lb_target_group" "tg_other" {  
  name     = "tg-other"  
  port     = 80  
  protocol = "HTTP"  
  vpc_id   =  module.vpc.aws_vpc
  target_type = "ip"
  health_check {  
    enabled             = true  
    interval            = 30  
    path                = "/" # Replace with your actual health check endpoint  
    port                = "traffic-port"  
    protocol            = "HTTP"  
    matcher             = "200"          # The HTTP response codes to indicate a healthy state  
    timeout             = 5  
    healthy_threshold   = 2  
    unhealthy_threshold = 2  
  }  
}  
  
# Create the second target group for /api traffic  
resource "aws_lb_target_group" "tg_api" {  
  name     = "tg-api"  
  port     = 80  
  protocol = "HTTP"  
  target_type = "ip"
  vpc_id   = module.vpc.aws_vpc # Replace with your actual VPC ID  
  health_check {  
    enabled             = true  
    interval            = 30  
    path                = "/" # Replace with your actual health check endpoint  
    port                = "traffic-port"  
    protocol            = "HTTP"  
    matcher             = "200"          # The HTTP response codes to indicate a healthy state  
    timeout             = 5  
    healthy_threshold   = 2  
    unhealthy_threshold = 2  
  }  
}  
  
# Create an HTTP listener  
resource "aws_lb_listener" "http_listener" {  
  load_balancer_arn = aws_lb.alb.arn  
  port              = 80  
  protocol          = "HTTP"  
  
  default_action {  
    type             = "forward"  
    target_group_arn = aws_lb_target_group.tg_other.arn  
  }  
}  
  
# Create a listener rule to forward /api traffic to the tg_api target group  
resource "aws_lb_listener_rule" "api_rule" {  
  listener_arn = aws_lb_listener.http_listener.arn  
  priority     = 100  
  
  action {  
    type             = "forward"  
    target_group_arn = aws_lb_target_group.tg_api.arn  
  }  
  
  condition {  
    path_pattern {  
      values = ["/api/*"]  
    }  
  }  
}  
*/
# Security group for the ALB  
resource "aws_security_group" "alb_sg" {  
  name        = "alb-sg"  
  description = "ALB Security Group"  
  vpc_id      = module.vpc.aws_vpc 
  
  ingress {  
    from_port   = 80  
    to_port     = 80  
    protocol    = "tcp"  
    cidr_blocks = ["0.0.0.0/0"]  
  }  
  
  ingress {  
    from_port   = 443  
    to_port     = 443  
    protocol    = "tcp"  
    cidr_blocks = ["0.0.0.0/0"]  
  }  
}  


# ------- ECS Role -------
module "ecs_role" {
  source             = "./Modules/IAM"
  create_ecs_role    = true
  name               = var.iam_role_name["ecs"]
  name_ecs_task_role = var.iam_role_name["ecs_task_role"]
  dynamodb_table     = ["${module.dynamodb_table.dynamodb_table_arn}"]
}

# ------- Creating a IAM Policy for role -------
module "ecs_role_policy" {
  source        = "./Modules/IAM"
  name          = "ecs-ecr-${var.environment_name}"
  create_policy = true
  attach_to     = module.ecs_role.name_role
}

# ------- Creating client ECR Repository to store Docker Images -------
module "ecr" {
  source = "./Modules/ECR"
  name   = "demo"
}

# ------- Creating ECS Task Definition for the server -------
module "ecs_taks_definition_server" {
  source             = "./Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-server"
  container_name     = var.container_name["server"]
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  cpu                = 512
  memory             = "1024"
  container_port     = var.port_app_server
  container_cpu      = "512"  
  container_memory   = "1024"    
  docker_image_url   = "${module.ecr.ecr_repository_url}:back"
  aws_region         = var.aws_region
}

# ------- Creating ECS Task Definition for the client -------
module "ecs_taks_definition_client" {
  source             = "./Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-client"
  container_name     = var.container_name["client"]
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  cpu                = 512
  memory             = "1024"  
  container_port     = var.port_app_client
  container_cpu      = "512"  
  container_memory   = "1024"    
  docker_image_url   = "${module.ecr.ecr_repository_url}:client"
  aws_region         = var.aws_region
}

# ------- Creating a server Security Group for ECS TASKS -------
module "security_group_ecs_task_server" {
  source          = "./Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-server"
  description     = "Controls access to the server ECS task"
  vpc_id          = module.vpc.aws_vpc
  ingress_port    = var.port_app_server
  security_groups = [aws_security_group.alb_sg.id]
}
# ------- Creating a client Security Group for ECS TASKS -------
module "security_group_ecs_task_client" {
  source          = "./Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-client"
  description     = "Controls access to the client ECS task"
  vpc_id          = module.vpc.aws_vpc
  ingress_port    = var.port_app_client
  security_groups = [aws_security_group.alb_sg.id]
}

# ------- Creating ECS Cluster -------
module "ecs_cluster" {
  source = "./Modules/ECS/Cluster"
  name   = var.environment_name
}

# ------- Creating ECS Service server -------
module "ecs_service_server" {
  depends_on          = [aws_lb.alb]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-server"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id
  arn_task_definition = module.ecs_taks_definition_server.arn_task_definition  
  security_group_ids  = [module.security_group_ecs_task_server.sg_id] 
  subnet_ids          = [module.vpc.private_subnets_server[0], module.vpc.private_subnets_server[1]]
  target_group_arn    = aws_lb_target_group.tg_api.arn
  desired_tasks       = 1
  container_port      = var.port_app_server
  container_memory    = "512"
  container_cpu       = 256
  execution_role_arn  = module.ecs_role.arn_role
  task_role_arn       = module.ecs_role.arn_role_ecs_task_role 
  docker_image_url    = module.ecr.ecr_repository_url 
  cpu                 = "256" 
  memory              = "512" 
  container_name      = var.container_name["server"] 
  aws_region          = var.aws_region 
}

# ------- Creating ECS Service client -------
module "ecs_service_client" {
  depends_on          = [aws_lb.alb]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-client"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id 
  arn_task_definition = module.ecs_taks_definition_client.arn_task_definition
  security_group_ids  = [module.security_group_ecs_task_client.sg_id]
  subnet_ids          = [module.vpc.private_subnets_client[0], module.vpc.private_subnets_client[1]]
  target_group_arn    = aws_lb_target_group.tg_other.arn
  desired_tasks       = 1
  container_port      = var.port_app_client
  container_memory    = "512"
  container_cpu       = 256
  execution_role_arn  = module.ecs_role.arn_role
  task_role_arn       = module.ecs_role.arn_role_ecs_task_role 
  docker_image_url    = module.ecr.ecr_repository_url
  cpu                 = "256" 
  memory              = "512" 
  container_name      = var.container_name["client"] 
  aws_region          = var.aws_region 
}

# ------- Creating ECS Autoscaling policies for the server application -------
module "ecs_autoscaling_server" {
  depends_on   = [module.ecs_service_server]
  source       = "./Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-server"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- Creating ECS Autoscaling policies for the client application -------
module "ecs_autoscaling_client" {
  depends_on   = [module.ecs_service_client]
  source       = "./Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-client"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- Creating a SNS topic -------
module "sns" {
  source   = "./Modules/SNS"
  sns_name = "sns-${var.environment_name}"
}

# ------- Creating Bucket to store assets accessed by the Back-end -------
module "s3_assets" {
  source      = "./Modules/S3"
  bucket_name = "assets-${var.aws_region}-${random_id.RANDOM_ID.hex}"
}

# ------- Creating Dynamodb table by the Back-end -------
module "dynamodb_table" {
  source = "./Modules/Dynamodb"
  name   = "assets-table-${var.environment_name}"
}
