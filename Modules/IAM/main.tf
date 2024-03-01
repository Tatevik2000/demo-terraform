resource "aws_iam_role" "ecs_task_excecution_role" {
  count              = var.create_ecs_role == true ? 1 : 0
  name               = var.name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Name = var.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs_task_role" {
  count              = var.create_ecs_role == true ? 1 : 0
  name               = var.name_ecs_task_role
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Name = var.name_ecs_task_role
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "policy_for_ecs_task_role" {
  count       = var.create_ecs_role == true ? 1 : 0
  name        = "Policy-${var.name_ecs_task_role}"
  description = "IAM Policy for Role ${var.name_ecs_task_role}"
  policy      = data.aws_iam_policy_document.role_policy_ecs_task_role.json

  lifecycle {
    create_before_destroy = true
  }
}

# ------- IAM Policies Attachments -------
resource "aws_iam_role_policy_attachment" "ecs_attachment" {
  count      = var.create_ecs_role == true ? 1 : 0
  policy_arn = aws_iam_policy.policy_for_ecs_task_role[0].arn
  role       = aws_iam_role.ecs_task_role[0].name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count      = length(aws_iam_role.ecs_task_excecution_role) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_excecution_role[0].name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "attachment2" {
  count      = var.create_devops_policy == true ? 1 : 0
  policy_arn = aws_iam_policy.policy_for_role[0].arn
  role       = var.attach_to

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "role_policy_ecs_task_role" {
  statement {
    sid    = "AllowS3Actions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = var.s3_bucket_assets
  }
  statement {
    sid    = "AllowIAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowDynamodbActions"
    effect = "Allow"
    actions = [
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
