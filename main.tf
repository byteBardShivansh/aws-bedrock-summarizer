terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM Role for Lambda with Bedrock access
resource "aws_iam_role" "lambda_bedrock_role" {
  name = "${var.project_name}-lambda-bedrock-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Bedrock access
resource "aws_iam_role_policy" "lambda_bedrock_policy" {
  name = "${var.project_name}-lambda-bedrock-policy"
  role = aws_iam_role.lambda_bedrock_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/meta.llama3-8b-instruct-v1:0"
        ]
      }
    ]
  })
}

# Attach AWS Lambda basic execution role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_bedrock_role.name
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-bedrock-lambda"
  retention_in_days = var.log_retention_days
  
  tags = var.tags
}

# Lambda function
resource "aws_lambda_function" "bedrock_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-bedrock-lambda"
  role            = aws_iam_role.lambda_bedrock_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 256

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      MODEL_ID = "meta.llama3-8b-instruct-v1:0"
      AWS_REGION = var.aws_region
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_logs,
  ]

  tags = var.tags
}

# Create ZIP file for Lambda deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# Lambda function URL (optional - for HTTP access)
resource "aws_lambda_function_url" "bedrock_lambda_url" {
  function_name      = aws_lambda_function.bedrock_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_bedrock_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Bedrock access
resource "aws_iam_policy" "lambda_bedrock_policy" {
  name        = "${var.function_name}-bedrock-policy"
  description = "Policy for Lambda to invoke Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/meta.llama3-8b-instruct-v1:0",
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/meta.llama3-70b-instruct-v1:0"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach Bedrock policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_bedrock_policy_attachment" {
  role       = aws_iam_role.lambda_bedrock_role.name
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_bedrock_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "bedrock_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_bedrock_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 256

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BEDROCK_REGION = var.aws_region
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_bedrock_policy_attachment,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}