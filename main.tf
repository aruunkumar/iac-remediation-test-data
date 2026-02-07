# Main Terraform configuration file
# This file orchestrates the modules and defines the dependencies between them

# Route53 Module
module "route53" {
  source      = "./modules/route53"
  domain_name = var.domain_name
}

# DynamoDB Module
module "dynamodb" {
  source                        = "./modules/dynamodb"
  table_name                    = var.table_name
  conversation_history_table_name = var.conversation_history_table_name
}

# Amplify Module
module "amplify" {
  source             = "./modules/amplify"
  app_name           = var.app_name
  amplify_branch_name = var.amplify_branch_name
  domain_name        = var.domain_name
  is_custom_domain   = var.is_custom_domain
  ui_source_dir      = "${path.root}/ui"
  depends_on         = [module.route53]
}

# Cognito Module
module "cognito" {
  source              = "./modules/cognito"
  app_name            = var.app_name
  federate_issuer_url = var.federate_issuer_url
  federate_client_id  = var.federate_client_id
  federate_secret     = var.federate_secret
  oidc_domain_prefix  = var.oidc_domain_prefix
  domain_name         = var.domain_name
  amplify_app_id      = module.amplify.amplify_app_id
  amplify_branch_name = var.amplify_branch_name
  region              = var.region
}

# API Gateway Module
module "api_gateway" {
  source                = "./modules/api_gateway"
  api_name              = var.api_name
  region                = var.region
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_user_pool_id  = module.cognito.user_pool_id
  table_name            = module.dynamodb.table_name
  chat_history_table_name = module.dynamodb.chat_history_table_name
  lambda_source_dir     = "${path.root}/api/lambda"
}
