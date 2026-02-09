# API Gateway module - Creates API Gateway, Lambda functions, and related resources

# Create IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "user_details_lambda_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM role for chat Lambda function
resource "aws_iam_role" "chat_lambda_role" {
  name = "chat_lambda_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to Lambda roles
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "dynamodb:*"
        Effect = "Allow"
        Resource = "arn:aws:dynamodb:${var.region}:*:table/${var.table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy" "chat_lambda_dynamodb_policy" {
  name = "chat_lambda_dynamodb_policy"
  role = aws_iam_role.chat_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "dynamodb:*"
        Effect = "Allow"
        Resource = "arn:aws:dynamodb:${var.region}:*:table/${var.chat_history_table_name}"
      }
    ]
  })
}

# Attach basic Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "chat_lambda_basic" {
  role       = aws_iam_role.chat_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# AGENT-FIXED: CKV_AWS_237 - Added create_before_destroy lifecycle policy for API Gateway
# Create API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "REST API Gateway"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create Cognito authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "UserDetailsAuthorizer"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# Create API resources
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "chat"
}

# AGENT-FIXED: CKV2_AWS_53 - Added request validator for API Gateway
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "${var.api_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# AGENT-FIXED: CKV2_AWS_53 - Added request validator to method
# Create API methods for user resource
resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "GET"
  authorization =  aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id
}

# Create API Gateway deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.user_get_integration,
    aws_api_gateway_integration.user_post_integration,
    aws_api_gateway_integration.user_put_integration,
    aws_api_gateway_integration.user_delete_integration,
    aws_api_gateway_integration.chat_post_integration,
    module.cors_user,
    module.cors_chat
  ]
  
  rest_api_id = aws_api_gateway_rest_api.api.id
  
  # Force a new deployment on changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.user.id,
      aws_api_gateway_resource.chat.id,
      aws_api_gateway_method.user_get.id,
      aws_api_gateway_method.user_post.id,
      aws_api_gateway_method.user_put.id,
      aws_api_gateway_method.user_delete.id,
      aws_api_gateway_method.chat_post.id
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# AGENT-FIXED: CKV_AWS_76 - Added CloudWatch log group for API Gateway access logging
# AGENT-FIXED: CKV_AWS_338 - Set retention to 365 days (1 year minimum)
# TODO: CKV_AWS_158 - CloudWatch Log Group is not encrypted by KMS
# Resource: aws_cloudwatch_log_group.api_gateway
# Reason: Requires a KMS key which is organization-specific and may not exist yet
# Fix: To enable KMS encryption for CloudWatch logs:
#   1. Create or identify an existing KMS key for CloudWatch Logs encryption
#   2. Ensure the KMS key policy allows CloudWatch Logs service to use it
#   3. Add the following argument to this resource:
#      kms_key_id = var.cloudwatch_kms_key_arn
#   4. Example KMS key policy statement needed:
#      {
#        "Effect": "Allow",
#        "Principal": { "Service": "logs.amazonaws.com" },
#        "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey"],
#        "Resource": "*",
#        "Condition": {
#          "ArnLike": {
#            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:REGION:ACCOUNT:log-group:/aws/apigateway/*"
#          }
#        }
#      }
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 365
}

# AGENT-FIXED: CKV2_AWS_51 - Created client certificate for API Gateway authentication
resource "aws_api_gateway_client_certificate" "cert" {
  description = "Client certificate for ${var.api_name}"
}

# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for API Gateway stage
# AGENT-FIXED: CKV_AWS_76 - Added access logging configuration with CloudWatch Logs
# AGENT-FIXED: CKV2_AWS_51 - Associated client certificate with stage
# TODO: CKV_AWS_120 - API Gateway caching is not enabled
# Resource: aws_api_gateway_stage.prod
# Reason: Enabling caching requires business decision on cache size and cost implications
# Fix: To enable caching:
#   1. Add cache_cluster_enabled = true to this stage resource
#   2. Add cache_cluster_size with appropriate size (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, or 237 GB)
#   3. Consider cost implications - caching incurs additional charges
#   4. Optionally configure aws_api_gateway_method_settings with caching_enabled = true for specific methods
# TODO: CKV2_AWS_29 - API Gateway is not protected by WAF
# Resource: aws_api_gateway_stage.prod
# Reason: Requires creation of WAF Web ACL with organization-specific security rules
# Fix: To enable WAF protection:
#   1. Create an aws_wafv2_web_acl resource with appropriate rules (rate limiting, IP filtering, SQL injection protection, etc.)
#   2. Ensure the WAF scope is set to "REGIONAL" for API Gateway
#   3. Create an aws_wafv2_web_acl_association resource linking the Web ACL to this stage's ARN
#   4. Example:
#      resource "aws_wafv2_web_acl_association" "api_gateway" {
#        resource_arn = aws_api_gateway_stage.prod.arn
#        web_acl_arn  = aws_wafv2_web_acl.api_gateway.arn
#      }
# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
  
  xray_tracing_enabled = true
  client_certificate_id = aws_api_gateway_client_certificate.cert.id
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# AGENT-FIXED: CKV2_AWS_4 - Added method settings with logging level defined
# TODO: CKV_AWS_225 - API Gateway method setting caching is not enabled
# Resource: aws_api_gateway_method_settings.all
# Reason: Method-level caching requires stage-level cache cluster to be enabled first (see CKV_AWS_120)
# Fix: To enable method-level caching:
#   1. First enable caching on the aws_api_gateway_stage.prod resource (cache_cluster_enabled = true)
#   2. Then add the following to the settings block below:
#      caching_enabled = true
#      cache_ttl_in_seconds = 300  # Adjust TTL as needed (0-3600 seconds)
#      cache_data_encrypted = true  # Encrypt cached data
#      require_authorization_for_cache_control = true  # Require auth for cache invalidation
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"
  
  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}

#   output_path = "${path.module}/chat_lambda.zip"
# }
