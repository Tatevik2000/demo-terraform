resource "aws_ecr_repository" "ecr_repository" {  
  name                 = var.name  
  image_tag_mutability = "MUTABLE"  
}  
  
data "aws_iam_policy_document" "policy" {  
  statement {  
    sid    = "PublicRead"  
    effect = "Allow"  
  
    principals {  
      type        = "*"  
      identifiers = ["*"]  
    }  
  
    actions = [  
      "ecr:GetDownloadUrlForLayer",  
      "ecr:BatchGetImage",  
      "ecr:BatchCheckLayerAvailability",  
    ]  
  }  
}  
  
resource "aws_ecr_repository_policy" "policy" {  
  repository = aws_ecr_repository.ecr_repository.name  
  policy     = data.aws_iam_policy_document.policy.json  
}  

