output "user_pool_id" {
  description = "The ID of the Cognito user pool"
  value       = aws_cognito_user_pool.pool.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito user pool"
  value       = aws_cognito_user_pool.pool.arn
}

output "app_client_id" {
  description = "The ID of the Cognito app client"
  value       = aws_cognito_user_pool_client.client.id
}

output "cognito_domain" {
  description = "The domain of the Cognito user pool"
  value       = "${var.oidc_domain_prefix}.auth.${var.region}.amazoncognito.com"
}