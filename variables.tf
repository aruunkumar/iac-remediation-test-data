variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "TrainingApp"
}

variable "ui_app_title" {
  description = "Title of the UI application"
  type        = string
  default     = "Employee Training Dashboard"
}

variable "api_name" {
  description = "Name of the API"
  type        = string
  default     = "UserDetailsAPI"
}

variable "table_name" {
  description = "Name of the main DynamoDB table"
  type        = string
  default     = "TrainingApp-Table"
}

variable "conversation_history_table_name" {
  description = "Name of the conversation history DynamoDB table"
  type        = string
  default     = "chat-history"
}

variable "amplify_branch_name" {
  description = "Name of the Amplify branch"
  type        = string
  default     = "main"
}

variable "app_env" {
  description = "Application environment"
  type        = string
  default     = "XXXXXX"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "federate_issuer_url" {
  description = "Federate issuer URL"
  type        = string
  default     = "https://idp-integ.federate.amazon.com"
}

variable "federate_client_id" {
  description = "Federate client ID"
  type        = string
  default     = "app-dev-fw-client"
}

variable "federate_secret" {
  description = "Federate client secret"
  type        = string
  default     = "jAzpvIxsapt9C5olt4sTedf3YZ14F0CC4vjnYy4aDpzN"
  sensitive   = true
}

variable "oidc_domain_prefix" {
  description = "OIDC domain prefix"
  type        = string
  default     = "appdev-fw-staging"
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = "appdev-framework.proserve.aws.dev"
}

variable "is_custom_domain" {
  description = "Whether to use a custom domain"
  type        = bool
  default     = false
}