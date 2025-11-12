variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "amplify_branch_name" {
  description = "The name of the Amplify branch"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the Amplify app"
  type        = string
}

variable "is_custom_domain" {
  description = "Whether to use a custom domain"
  type        = bool
}

variable "ui_source_dir" {
  description = "The directory containing the UI source code"
  type        = string
}