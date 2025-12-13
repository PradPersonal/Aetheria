# ECR Repositories for each microservice
resource "aws_ecr_repository" "services" {
  for_each = toset(var.ecr_repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"

  # Enable image scanning for security
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encryption configuration
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Service = each.value
  })
}

# ECR Lifecycle policies for cost optimization
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod", "production"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 staging images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging", "stage"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep last 3 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "develop", "feature"]
          countType     = "imageCountMoreThan"
          countNumber   = 3
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository policy for cross-account access (if needed)
resource "aws_ecr_repository_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            var.cluster_iam_role_arn,
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
      }
    ]
  })
}

# IAM policy for ECR access from EKS nodes
resource "aws_iam_policy" "ecr_access" {
  name_prefix = "${var.name}-ecr-access"
  description = "Policy for EKS nodes to access ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Resource = [
          for repo in aws_ecr_repository.services : repo.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach ECR policy to node group role
resource "aws_iam_role_policy_attachment" "node_group_ecr_access" {
  policy_arn = aws_iam_policy.ecr_access.arn
  role       = var.node_group_iam_role_name
}

# Data sources
data "aws_caller_identity" "current" {}