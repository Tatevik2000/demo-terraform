data "aws_route53_zone" "zone" {
  name = "testofalamashxarh.link"
} 

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = var.rt_zone_name
  zone_id      = data.aws_route53_zone.zone.zone_id

  subject_alternative_names = [
    "*.${var.rt_zone_name}"
  ]

  create_certificate = var.acm_create_certificate
  
  tags               = var.tags
}


module "acm_cloudfront" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.us-east-1
  }
  
  domain_name  = var.rt_zone_name
  zone_id      = data.aws_route53_zone.zone.zone_id

  subject_alternative_names = [
    "*.${var.rt_zone_name}",
  ]

  create_certificate = var.acm_create_certificate
  
  tags               = var.tags
}

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

 module "alb" {
  source = "terraform-aws-modules/alb/aws"
  name    = "${var.environment_name}-alb" 
  vpc_id  = module.vpc.aws_vpc
  subnets = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]] 
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.120.0.0/16"
    }
  }

  listeners = {
    ex-http-https = {
      port     = 80
      protocol = "HTTP"
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "module.acm.acm_certificate_arn"

      forward = {
        target_group_key = "ex-instance"
      }
    }
  }
    target_groups = [
    {
      name_prefix      = "front"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      
      health_check = {
          matcher = "200-299"
          path    = "/status"
      }
    },
    {
      name_prefix      = "h1"
      protocol         = "back"
      port             = 80
      target_type      = "instance"
      
      health_check = {
          matcher = "200-299"
          path    = "/status"
      }
    }
  ]
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
  security_groups = [module.alb.security_group_id]
}
# ------- Creating a client Security Group for ECS TASKS -------
module "security_group_ecs_task_client" {
  source          = "./Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-client"
  description     = "Controls access to the client ECS task"
  vpc_id          = module.vpc.aws_vpc
  ingress_port    = var.port_app_client
  security_groups = [module.alb.security_group_id]
}

# ------- Creating ECS Cluster -------
module "ecs_cluster" {
  source = "./Modules/ECS/Cluster"
  name   = var.environment_name
}

# ------- Creating ECS Service server -------
module "ecs_service_server" {
  depends_on          = [module.alb]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-server"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id
  arn_task_definition = module.ecs_taks_definition_server.arn_task_definition  
  security_group_ids  = [module.security_group_ecs_task_server.sg_id] 
  subnet_ids          = [module.vpc.private_subnets_server[0], module.vpc.private_subnets_server[1]]
  target_group_arn    = module.alb.target_groups[0]
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
  depends_on          = [module.alb]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-client"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id 
  arn_task_definition = module.ecs_taks_definition_client.arn_task_definition
  security_group_ids  = [module.security_group_ecs_task_client.sg_id]
  subnet_ids          = [module.vpc.private_subnets_client[0], module.vpc.private_subnets_client[1]]
  target_group_arn    = module.alb.target_groups[1]
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
