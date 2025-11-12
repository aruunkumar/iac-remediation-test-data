variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "ui_app_title" {
  description = "The title of the UI application"
  type        = string
}

variable "amplify_branch_name" {
  description = "The name of the Amplify branch"
  type        = string
}

variable "amplify_app_id" {
  description = "The ID of the Amplify app"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "is_custom_domain" {
  description = "Whether to use a custom domain"
  type        = bool
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "oidc_domain_prefix" {
  description = "The domain prefix for the OIDC provider"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "The ID of the Cognito user pool"
  type        = string
}

variable "cognito_app_client_id" {
  description = "The ID of the Cognito app client"
  type        = string
}

variable "api_id" {
  description = "The ID of the API Gateway REST API"
  type        = string
}

variable "repo_name" {
  description = "The name of the CodeCommit repository"
  type        = string
}