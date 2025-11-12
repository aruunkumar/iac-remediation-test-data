variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "federate_issuer_url" {
  description = "The URL of the federate issuer"
  type        = string
}

variable "federate_client_id" {
  description = "The client ID for the federate service"
  type        = string
}

variable "federate_secret" {
  description = "The client secret for the federate service"
  type        = string
  sensitive   = true
}

variable "oidc_domain_prefix" {
  description = "The domain prefix for the OIDC provider"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "amplify_app_id" {
  description = "The ID of the Amplify app"
  type        = string
}

variable "amplify_branch_name" {
  description = "The name of the Amplify branch"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}