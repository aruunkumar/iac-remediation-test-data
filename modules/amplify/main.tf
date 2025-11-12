# Amplify module - Creates an AWS Amplify app, CodeCommit repository, and related resources

# Create CodeCommit repository for UI code
# resource "aws_codecommit_repository" "ui_repo" {
#   repository_name = "${var.app_name}-UI"
#   description     = "UI Code Repository"
# }

# Create IAM role for Amplify
resource "aws_iam_role" "amplify_role" {
  name = "Amplify-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Amplify admin policy to the role
resource "aws_iam_role_policy_attachment" "amplify_admin" {
  role       = aws_iam_role.amplify_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

# Create Amplify app
resource "aws_amplify_app" "app" {
  name       = var.app_name
  # repository = aws_codecommit_repository.ui_repo.clone_url_http
  iam_service_role_arn = aws_iam_role.amplify_role.arn
  
  # Add custom rules for SPA routing
  custom_rule {
    source = "</^((?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf)$).)*$/>"
    target = "/index.html"
    status = "200"
  }
}

# Create Amplify branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.app.id
  branch_name = var.amplify_branch_name
}

# Add custom domain to Amplify App if enabled
resource "aws_amplify_domain_association" "custom_domain" {
  count       = var.is_custom_domain ? 1 : 0
  app_id      = aws_amplify_app.app.id
  domain_name = var.domain_name
  
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
}

# Upload UI code to CodeCommit repository
# Note: In a real implementation, you would use a more robust approach to upload code
# This is a simplified version using local-exec provisioner
# resource "null_resource" "upload_ui_code" {
#   triggers = {
#     ui_source_dir_hash = sha256(join("", [for f in fileset(var.ui_source_dir, "**") : filesha256("${var.ui_source_dir}/${f}")]))
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       # This is a placeholder for the code upload logic
#       # In a real implementation, you would use AWS CLI or other tools to upload code to CodeCommit
#       echo "Uploading UI code to CodeCommit repository ${aws_codecommit_repository.ui_repo.repository_name}"
#     EOT
#   }

#   depends_on = [aws_codecommit_repository.ui_repo]
# }