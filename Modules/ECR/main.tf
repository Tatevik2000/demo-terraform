resource "aws_ecr_repository" "ecr_repository" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [{
      Sid       = "AllowPull"
      Effect    = "Allow"
      Principal = "*"
      Action    = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken"
      ]
    }]
  })
}
