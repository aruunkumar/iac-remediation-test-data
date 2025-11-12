# Route53 outputs
output "hosted_zone_id" {
  description = "The ID of the hosted zone"
  value       = module.route53.hosted_zone_id
}

output "supernova_role_arn" {
  description = "The ARN of the SuperNova role"
  value       = module.route53.supernova_role_arn
}

# DynamoDB outputs
output "table_name" {
  description = "The name of the main DynamoDB table"
  value       = module.dynamodb.table_name
}

output "chat_history_table_name" {
  description = "The name of the chat history DynamoDB table"
  value       = module.dynamodb.chat_history_table_name
}

# Amplify outputs
output "amplify_app_id" {
  description = "The ID of the Amplify app"
  value       = module.amplify.amplify_app_id
}

output "amplify_domain" {
  description = "The domain of the Amplify app"
  value       = module.amplify.amplify_domain
}

output "repo_name" {
  description = "The name of the CodeCommit repository"
  value       = module.amplify.repo_name
}

# Cognito outputs
output "user_pool_id" {
  description = "The ID of the Cognito user pool"
  value       = module.cognito.user_pool_id
}

output "app_client_id" {
  description = "The ID of the Cognito app client"
  value       = module.cognito.app_client_id
}

# API Gateway outputs
output "api_id" {
  description = "The ID of the API Gateway REST API"
  value       = module.api_gateway.api_id
}

output "api_url" {
  description = "The URL of the API Gateway REST API"
  value       = module.api_gateway.api_url
}