output "api_id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_url" {
  description = "The URL of the API Gateway REST API"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "user_details_lambda_arn" {
  description = "The ARN of the user details Lambda function"
  value       = aws_lambda_function.user_details_lambda.arn
}

output "chat_lambda_arn" {
  description = "The ARN of the chat Lambda function"
  value       = aws_lambda_function.chat_lambda.arn
}