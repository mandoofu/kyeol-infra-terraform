# ECR Module: 메인 리소스

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repository_names)

  name                 = "${var.name_prefix}-${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value}"
  })
}

# Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  for_each = var.lifecycle_policy_enabled ? toset(var.repository_names) : toset([])

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
