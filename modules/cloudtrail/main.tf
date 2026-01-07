# CloudTrail Module - Phase 3
# 계정 레벨 감사 로그 수집
# 권장: 계정당 1개의 Trail만 생성 (prod 또는 mgmt 환경에서)

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Audit 로그용 S3 버킷
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.name_prefix}-audit-logs"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-audit-logs"
    Purpose = "cloudtrail-audit-logs"
    Phase   = "3"
  })
}

resource "aws_s3_bucket_versioning" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms_encryption ? var.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {} # 모든 객체에 적용

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555 # 7년 (규정 준수)
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - CloudTrail 전용 + TLS 강제
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "audit" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${var.aws_account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit[0].arn}/cloudtrail/${var.aws_account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${var.aws_account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit[0].arn,
          "${aws_s3_bucket.audit[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group (선택)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.cloudwatch_log_group_retention

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-cloudtrail-logs"
    Phase = "3"
  })
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-cloudtrail-cw-role"
    Phase = "3"
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  name = "${var.name_prefix}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

# -----------------------------------------------------------------------------
# CloudTrail
# -----------------------------------------------------------------------------
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.audit[0].id
  s3_key_prefix                 = "cloudtrail/${var.aws_account_id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  # KMS 암호화 (선택)
  kms_key_id = var.enable_kms_encryption ? var.kms_key_arn : null

  # CloudWatch Logs 연동 (선택)
  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null

  # 데이터 이벤트 (선택 - 비용 주의)
  dynamic "event_selector" {
    for_each = var.enable_data_events ? [1] : []
    content {
      read_write_type           = "All"
      include_management_events = true

      data_resource {
        type   = "AWS::S3::Object"
        values = ["arn:aws:s3"]
      }
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-trail"
    Phase = "3"
  })

  depends_on = [aws_s3_bucket_policy.audit]
}
