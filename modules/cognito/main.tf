# Cognito module - Creates a Cognito user pool, identity provider, and client

# Create Cognito User Pool
resource "aws_cognito_user_pool" "pool" {
  name = "${var.app_name}-UserPool"
  
  # Enable self-signup
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

# Create OIDC Identity Provider
resource "aws_cognito_identity_provider" "oidc_provider" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "AmazonFederate"
  provider_type = "OIDC"
  
  provider_details = {
    client_id     = var.federate_client_id
    client_secret = var.federate_secret
    authorize_scopes = "openid email profile"
    attributes_request_method = "GET"
    oidc_issuer   = var.federate_issuer_url
  }
  
  attribute_mapping = {
    email     = "EMAIL"
    given_name = "GIVEN_NAME"
    family_name = "FAMILY_NAME"
  }
}

# Determine callback URLs based on custom domain setting
locals {
  amplify_domain = "https://${var.amplify_branch_name}.${var.amplify_app_id}.amplifyapp.com/"
  custom_domain = "https://www.${var.domain_name}/"
  
  callback_urls = [
    "http://localhost:3000/",
    local.custom_domain,
    local.amplify_domain
  ]
  
  logout_urls = [
    "http://localhost:3000/",
    local.custom_domain,
    local.amplify_domain
  ]
}

# Create Cognito User Pool Client
resource "aws_cognito_user_pool_client" "client" {
  name = "webapp-client"
  user_pool_id = aws_cognito_user_pool.pool.id
  
  generate_secret = false
  
  # Auth flows
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["openid", "email", "profile"]
  
  # Callback and logout URLs
  callback_urls = local.callback_urls
  logout_urls = local.logout_urls
  
  # Token validity
  access_token_validity = 10
  id_token_validity = 60
  refresh_token_validity = 600
  
  # Token validity units
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "hours"
  }
  
  # Supported identity providers
  supported_identity_providers = [aws_cognito_identity_provider.oidc_provider.provider_name]
}

# Create Cognito Domain
resource "aws_cognito_user_pool_domain" "domain" {
  domain       = var.oidc_domain_prefix
  user_pool_id = aws_cognito_user_pool.pool.id
}