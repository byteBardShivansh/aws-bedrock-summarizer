output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.arn
}

output "lambda_function_url" {
  description = "URL of the Lambda function"
  value       = aws_lambda_function_url.bedrock_lambda_url.function_url
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_bedrock_role.arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.bedrock_lambda.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_bedrock_role.arn
}

output "lambda_invoke_url" {
  description = "URL to invoke the Lambda function (for testing)"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.bedrock_lambda.function_name} --payload '{\"prompt\":\"Hello from Llama 3!\"}' response.json"
}