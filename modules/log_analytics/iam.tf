# =============================================================================
# Log Analytics Module: IAM 역할 및 정책
# Lambda 실행 권한, Bedrock 호출 권한, Athena/S3 접근 권한
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda 실행 역할 (공통)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_execution" {
  name = "${var.name_prefix}-log-analytics-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-log-analytics-lambda-role"
  })
}

# CloudWatch Logs 기본 권한
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# S3 접근 정책 (감사 로그 읽기 + 리포트 쓰기)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.name_prefix}-s3-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadAuditLogs"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.audit_bucket_name}",
          "arn:aws:s3:::${var.audit_bucket_name}/*"
        ]
      },
      {
        Sid    = "WriteReports"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.reports.arn,
          "${aws_s3_bucket.reports.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Athena 쿼리 권한
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "athena_access" {
  name = "${var.name_prefix}-athena-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AthenaQuery"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution"
        ]
        Resource = [
          "arn:aws:athena:${var.aws_region}:${var.aws_account_id}:workgroup/${aws_athena_workgroup.logs.name}"
        ]
      },
      {
        Sid    = "GlueAccess"
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:database/${aws_athena_database.logs.name}",
          "arn:aws:glue:${var.aws_region}:${var.aws_account_id}:table/${aws_athena_database.logs.name}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Bedrock 호출 권한 (Claude Haiku)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "bedrock_access" {
  name = "${var.name_prefix}-bedrock-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "BedrockInvoke"
      Effect = "Allow"
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ]
      Resource = [
        "arn:aws:bedrock:${var.bedrock_region}::foundation-model/${var.bedrock_model_id}"
      ]
    }]
  })
}

# -----------------------------------------------------------------------------
# Secrets Manager 접근 (Slack Webhook URL)
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "slack_webhook" {
  name        = "${var.name_prefix}-slack-webhook"
  description = "Slack Webhook URL for security alerts"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-slack-webhook"
  })
}

resource "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id     = aws_secretsmanager_secret.slack_webhook.id
  secret_string = var.slack_webhook_url
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.name_prefix}-secrets-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GetSlackWebhook"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.slack_webhook.arn
      ]
    }]
  })
}
