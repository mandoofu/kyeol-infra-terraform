# Lambda@Edge Module - Phase 3 신규 모듈
# us-east-1 리전 필수 (모듈 호출 시 providers 전달)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Lambda 소스 코드 압축
# -----------------------------------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda-${var.name_prefix}-${var.function_name_suffix}.zip"
}

# -----------------------------------------------------------------------------
# Lambda@Edge 함수
# publish = true 필수 (버전 발행 필요)
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "edge" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.name_prefix}-${var.function_name_suffix}"
  role             = aws_iam_role.lambda_edge.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  publish          = true # 버전 발행 필수 (CloudFront 연결용)

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-${var.function_name_suffix}"
    Phase = "3"
  })
}

# -----------------------------------------------------------------------------
# Lambda@Edge용 IAM Role
# edgelambda.amazonaws.com 서비스 principal 필수
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda_edge" {
  name = "${var.name_prefix}-lambda-edge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-lambda-edge-role"
    Phase = "3"
  })
}

# -----------------------------------------------------------------------------
# Lambda 기본 실행 권한 (CloudWatch Logs)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_edge.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
