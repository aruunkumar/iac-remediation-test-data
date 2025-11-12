output "amplify_app_id" {
  description = "The ID of the Amplify app"
  value       = aws_amplify_app.app.id
}

output "amplify_domain" {
  description = "The domain of the Amplify app"
  value       = aws_amplify_app.app.default_domain
}

output "repo_name" {
  description = "The name of the CodeCommit repository"
  value       = aws_codecommit_repository.ui_repo.repository_name
}

output "repo_clone_url_http" {
  description = "The HTTP clone URL of the CodeCommit repository"
  value       = aws_codecommit_repository.ui_repo.clone_url_http
}