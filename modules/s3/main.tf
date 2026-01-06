# S3 Module - Phase 3 신규 모듈
# 미디어 및 로그 저장용 S3 버킷
# ISMS-P 준수 보안 기본값 강제 적용

# -----------------------------------------------------------------------------
# 미디어 버킷 (이미지, 정적 파일)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "media" {
  count  = var.create_media_bucket ? 1 : 0
  bucket = "${var.name_prefix}-media"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-media"
    Purpose = "media-storage"
    Phase   = "3"
  })
}

resource "aws_s3_bucket_versioning" "media" {
  count  = var.create_media_bucket ? 1 : 0
  bucket = aws_s3_bucket.media[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  count  = var.create_media_bucket ? 1 : 0
  bucket = aws_s3_bucket.media[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  count  = var.create_media_bucket ? 1 : 0
  bucket = aws_s3_bucket.media[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "media" {
  count  = var.create_media_bucket ? 1 : 0
  bucket = aws_s3_bucket.media[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# -----------------------------------------------------------------------------
# 로그 버킷 (ALB, WAF, CloudFront 로그)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = "${var.name_prefix}-logs"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-logs"
    Purpose = "log-storage"
    Phase   = "3"
  })
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms_encryption ? var.kms_key_arn : null
    }
    bucket_key_enabled = true
  }
}

# TLS 강제 Bucket Policy (P0: 필수)
resource "aws_s3_bucket_policy" "logs_tls" {
  count  = var.create_logs_bucket && var.enforce_tls ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs[0].arn,
          "${aws_s3_bucket.logs[0].arn}/*"
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


resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = var.logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# -----------------------------------------------------------------------------
# WAF 로그용 버킷 정책 (선택사항 - WAF 로깅 활성화 시 필요)
# 버킷 이름이 aws-waf-logs- 접두사를 가져야 WAF 로그 전송 가능
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "waf_logs" {
  count  = var.create_waf_logs_bucket ? 1 : 0
  bucket = "aws-waf-logs-${var.name_prefix}"

  tags = merge(var.tags, {
    Name    = "aws-waf-logs-${var.name_prefix}"
    Purpose = "waf-log-storage"
    Phase   = "3"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  count  = var.create_waf_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count  = var.create_waf_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  count  = var.create_waf_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.waf_logs[0].id

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"

    expiration {
      days = var.logs_retention_days
    }
  }
}
