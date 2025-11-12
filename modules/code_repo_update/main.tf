# # CodeRepoUpdate module - Updates the CodeCommit repository with environment variables

# # Determine redirect URI based on custom domain setting
# locals {
#   redirect_uri = var.is_custom_domain ? "https://www.${var.domain_name}/" : "https://${var.amplify_branch_name}.${var.amplify_app_id}.amplifyapp.com/"
  
#   # Environment variables to be written to .env file
#   env_vars = [
#     "REACT_APP_NAME=${var.ui_app_title}",
#     "REACT_APP_COGNITO_DOMAIN=${var.oidc_domain_prefix}.auth.${var.region}.amazoncognito.com/",
#     "REACT_APP_COGNITO_USERPOOL=${var.cognito_user_pool_id}",
#     "REACT_APP_COGNITO_USERPOOL_CLIENT=${var.cognito_app_client_id}",
#     "REACT_APP_OAUTH_REDIRECT_SIGNIN_URL=${local.redirect_uri}",
#     "REACT_APP_OAUTH_REDIRECT_SIGNOUT_URL=${local.redirect_uri}",
#     "REACT_APP_COGNITO_REGION=${var.region}",
#     "REACT_APP_API_BASE_URL=https://${var.api_id}.execute-api.${var.region}.amazonaws.com/prod"
#   ]
  
#   # Join environment variables with newlines
#   env_file_content = join("\n", local.env_vars)
# }

# # Create a local file with environment variables
# resource "local_file" "env_file" {
#   content  = local.env_file_content
#   filename = "${path.module}/.env"
# }

# # Use AWS provider to get the latest commit ID
# data "aws_codecommit_repository" "repo" {
#   repository_name = var.repo_name
# }

# # Use null_resource to update the CodeCommit repository
# resource "null_resource" "update_repo" {
#   triggers = {
#     env_file_content = local.env_file_content
#   }
  
#   # Use local-exec provisioner to update the repository
#   # Note: In a real implementation, you would use AWS CLI or other tools to update the repository
#   provisioner "local-exec" {
#     command = <<-EOT
#       # This is a placeholder for the code to update the CodeCommit repository
#       # In a real implementation, you would use AWS CLI to update the repository
#       echo "Updating CodeCommit repository ${var.repo_name} with environment variables"
#       echo "Environment variables:"
#       echo "${local.env_file_content}"
#     EOT
#   }
  
#   depends_on = [local_file.env_file]
# }