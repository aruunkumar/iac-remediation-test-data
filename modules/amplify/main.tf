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

#   depends_on = [aws_codecommit_repository.ui_repo]
# }
