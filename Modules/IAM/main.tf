# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.  
# SPDX-License-Identifier: MIT-0  
  
/*===========================================  
      AWS IAM for different resources  
============================================*/  
  
# ------- IAM Roles -------  
resource "aws_iam_role" "ecs_task_excecution_role" {  
  count              = var.create_ecs_role 
  name               = var.name  
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json  
  tags = {  
    Name = var.name  
  }  
  
  lifecycle {  
    create_before_destroy = true  
  }  
}  
  
resource "aws_iam_role" "ecs_task_role" {  
  count              = var.create_ecs_role 
  name               = var.name_ecs_task_role  
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json  
  tags = {  
    Name = var.name_ecs_task_role  
  }  
  
  lifecycle {  
    create_before_destroy = true  
  }  
}  
  
# ------- IAM Policies -------  
resource "aws_iam_policy" "policy_for_ecs_task_role" {  
  count       = var.create_ecs_role ? 1 : 0  
  name        = "Policy-${var.name_ecs_task_role}"  
  description = "IAM Policy for Role ${var.name_ecs_task_role}"  
  policy      = data.aws_iam_policy_document.role_policy_ecs_task_role.json  
  
  lifecycle {  
    create_before_destroy = true  
  }  
}  
  
# ------- IAM Policies Attachments -------  
resource "aws_iam_role_policy_attachment" "ecs_attachment" {  
  count      = var.create_ecs_role ? 1 : 0  
  policy_arn = aws_iam_policy.policy_for_ecs_task_role[0].arn  
  role       = aws_iam_role.ecs_task_role[0].name  
  
  lifecycle {  
    create_before_destroy = true  
  }  
}  
  
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {  
  count      = length(aws_iam_role.ecs_task_excecution_role) > 0 ? 1 : 0  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"  
  role       = aws_iam_role.ecs_task_excecution_role[0].name  
  
  lifecycle {  
    create_before_destroy = true  
  }  
}  
  
# ------- IAM Policy Documents -------  
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {  
  statement {  
    sid       = ""  
    effect    = "Allow"  
    principals {  
      type        = "Service"  
      identifiers = ["ecs-tasks.amazonaws.com"]  
    }  
    actions   = ["sts:AssumeRole"]  
  }  
}  
  
data "aws_iam_policy_document" "role_policy_ecs_task_role" {  
  statement {  
    sid       = "AllowS3Actions"  
    effect    = "Allow"  
    actions   = [  
      "s3:GetObject",  
      "s3:ListBucket"  
    ]  
    resources = var.s3_bucket_assets  
  }  
  statement {  
    sid       = "AllowIAMPassRole"  
    effect    = "Allow"  
    actions   = [  
      "iam:PassRole"  
    ]  
    resources = ["*"]  
  }  
  statement {  
    sid       = "AllowDynamodbActions"  
    effect    = "Allow"  
    actions   = [  
      "dynamodb:BatchGetItem",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = var.dynamodb_table
  }
}
