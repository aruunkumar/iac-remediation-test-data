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

# AGENT-FIXED: CKV_AWS_76 - Added CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/apigateway/${var.api_name}/access-logs"
  retention_in_days = 7
}

# AGENT-FIXED: CKV2_AWS_4 - Added CloudWatch Log Group for API Gateway execution logs
resource "aws_cloudwatch_log_group" "api_gateway_execution_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/prod"
  retention_in_days = 7
}

# AGENT-FIXED: CKV_AWS_76, CKV2_AWS_4 - Created IAM role for API Gateway CloudWatch logging
data "aws_iam_policy_document" "api_gateway_cloudwatch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name               = "${var.api_name}_api_gateway_cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_cloudwatch_assume_role.json
}

data "aws_iam_policy_document" "api_gateway_cloudwatch_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name   = "api_gateway_cloudwatch_policy"
  role   = aws_iam_role.api_gateway_cloudwatch.id
  policy = data.aws_iam_policy_document.api_gateway_cloudwatch_policy.json
}

# AGENT-FIXED: CKV_AWS_76, CKV2_AWS_4 - Set CloudWatch role ARN for API Gateway account-level logging
resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# AGENT-FIXED: CKV_AWS_237 - Added lifecycle block with create_before_destroy to ensure zero-downtime deployments
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

# TODO: CKV2_AWS_53 - API Gateway method requires request validation
# Resource: aws_api_gateway_method.user_get
# Reason: Request validation requires defining API request parameters and/or request body models based on the API specification, which are application-specific
# Fix: To remediate this issue:
#   1. Create an aws_api_gateway_request_validator resource:
#      resource "aws_api_gateway_request_validator" "validator" {
#        name                        = "request-validator"
#        rest_api_id                 = aws_api_gateway_rest_api.api.id
#        validate_request_body       = true
#        validate_request_parameters = true
#      }
#   2. Define request_parameters in the method if query strings or headers need validation
#   3. Create aws_api_gateway_model resources if body validation is needed
#   4. Add request_validator_id to this method:
#      request_validator_id = aws_api_gateway_request_validator.validator.id
# Create API methods for user resource
resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "GET"
  authorization =  aws_api_gateway_authorizer.cognito.id
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

# AGENT-FIXED: CKV_AWS_120 - Enabled cache cluster for improved performance and reduced backend load
# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for request tracking and debugging
# AGENT-FIXED: CKV_AWS_76 - Added access_log_settings with CloudWatch Logs destination
# TODO: CKV2_AWS_51 - API Gateway stage requires client certificate authentication
# Resource: aws_api_gateway_stage.prod
# Reason: Client certificate authentication requires certificate provisioning and backend service configuration to validate certificates, which are organization-specific decisions
# Fix: To remediate this issue:
#   1. Create an API Gateway client certificate:
#      resource "aws_api_gateway_client_certificate" "cert" {
#        description = "Client certificate for backend authentication"
#      }
#   2. Add client_certificate_id to this stage:
#      client_certificate_id = aws_api_gateway_client_certificate.cert.id
#   3. Configure backend services to validate the client certificate
#   4. Distribute the certificate (cert.pem_encoded_certificate) to backend systems
# TODO: CKV2_AWS_29 - API Gateway stage requires WAF protection
# Resource: aws_api_gateway_stage.prod
# Reason: WAF protection requires defining security rules based on threat model and traffic patterns, which are organization-specific
# Fix: To remediate this issue:
#   1. Create or reference a WAFv2 Web ACL with appropriate rules:
#      resource "aws_wafv2_web_acl" "api_waf" {
#        name  = "api-gateway-waf"
#        scope = "REGIONAL"
#        default_action {
#          allow {}
#        }
#        visibility_config {
#          cloudwatch_metrics_enabled = true
#          metric_name                = "api-gateway-waf-metrics"
#          sampled_requests_enabled   = true
#        }
#        # Add rules for rate limiting, IP filtering, SQL injection protection, etc.
#      }
#   2. Associate the WAF with the API Gateway stage:
#      resource "aws_wafv2_web_acl_association" "api_waf" {
#        resource_arn = aws_api_gateway_stage.prod.arn
#        web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
#      }
# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  depends_on = [
    aws_api_gateway_account.api_gateway_account,
    aws_cloudwatch_log_group.api_gateway_access_logs,
    aws_cloudwatch_log_group.api_gateway_execution_logs
  ]
  
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
  xray_tracing_enabled  = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
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

# AGENT-FIXED: CKV2_AWS_4 - Added method settings with logging level for execution logs
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "ERROR"
    data_trace_enabled = false
  }
}

#   output_path = "${path.module}/chat_lambda.zip"
# }
