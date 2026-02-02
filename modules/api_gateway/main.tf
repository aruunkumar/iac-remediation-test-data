# API Gateway module - Creates API Gateway, Lambda functions, and related resources

# Create Lambda function for user details
# resource "aws_lambda_function" "user_details_lambda" {
#   function_name = "UserDetailsLambda"
#   handler       = "user_details.lambda_handler"
#   runtime       = "python3.8"
  
#   filename      = data.archive_file.user_details_lambda_zip.output_path
#   source_code_hash = data.archive_file.user_details_lambda_zip.output_base64sha256
  
#   environment {
#     variables = {
#       TableName = var.table_name
#     }
#   }
  
#   role = aws_iam_role.lambda_role.arn
# }

# # Create Lambda function for AI chat
# resource "aws_lambda_function" "chat_lambda" {
#   function_name = "ai-chat"
#   handler       = "ai_chat.lambda_handler"
#   runtime       = "python3.12"
  
#   filename      = data.archive_file.chat_lambda_zip.output_path
#   source_code_hash = data.archive_file.chat_lambda_zip.output_base64sha256
  
#   environment {
#     variables = {
#       TableName = var.chat_history_table_name
#     }
#   }
  
#   role = aws_iam_role.chat_lambda_role.arn
# }

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

# AGENT-FIXED: CKV_AWS_237 - Added lifecycle block with create_before_destroy for API Gateway REST API
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

# AGENT-FIXED: CKV2_AWS_51 - Created client certificate for API Gateway mutual TLS authentication
resource "aws_api_gateway_client_certificate" "api_cert" {
  description = "Client certificate for ${var.api_name} API Gateway"
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

# # Enable CORS for API Gateway
# module "cors_user" {
#   source  = "./cors"
  
#   api_id          = aws_api_gateway_rest_api.api.id
#   resource_id     = aws_api_gateway_resource.user.id
#   authorizer_id   = aws_api_gateway_authorizer.cognito.id
# }

# module "cors_chat" {
#   source  = "./cors"
  
#   api_id          = aws_api_gateway_rest_api.api.id
#   resource_id     = aws_api_gateway_resource.chat.id
#   authorizer_id   = aws_api_gateway_authorizer.cognito.id
# }

# AGENT-FIXED: CKV2_AWS_53 - Created request validator for API Gateway to validate requests
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "${var.api_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
}

# AGENT-FIXED: CKV2_AWS_53 - Added request_validator_id to enable request validation
# Create API methods for user resource
resource "aws_api_gateway_method" "user_get" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.user.id
  http_method          = "GET"
  authorization        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id
}

# resource "aws_api_gateway_method" "user_post" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.user.id
#   http_method   = "POST"
#   authorization = aws_api_gateway_authorizer.cognito.id
# }

# resource "aws_api_gateway_method" "user_put" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.user.id
#   http_method   = "PUT"
#   authorization = aws_api_gateway_authorizer.cognito.id
# }

# resource "aws_api_gateway_method" "user_delete" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.user.id
#   http_method   = "DELETE"
#   authorization = aws_api_gateway_authorizer.cognito.id
# }

# # Create API method for chat resource
# resource "aws_api_gateway_method" "chat_post" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.chat.id
#   http_method   = "POST"
#   authorization = aws_api_gateway_authorizer.cognito.id
# }

# Create Lambda integrations
# resource "aws_api_gateway_integration" "user_get_integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.user.id
#   http_method = aws_api_gateway_method.user_get.http_method
  
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.user_details_lambda.invoke_arn
# }

# resource "aws_api_gateway_integration" "user_post_integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.user.id
#   http_method = aws_api_gateway_method.user_post.http_method
  
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.user_details_lambda.invoke_arn
# }

# resource "aws_api_gateway_integration" "user_put_integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.user.id
#   http_method = aws_api_gateway_method.user_put.http_method
  
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.user_details_lambda.invoke_arn
# }

# resource "aws_api_gateway_integration" "user_delete_integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.user.id
#   http_method = aws_api_gateway_method.user_delete.http_method
  
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.user_details_lambda.invoke_arn
# }

# resource "aws_api_gateway_integration" "chat_post_integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.chat.id
#   http_method = aws_api_gateway_method.chat_post.http_method
  
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.chat_lambda.invoke_arn
# }

# Create Lambda permissions
# resource "aws_lambda_permission" "user_details_lambda_permission" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.user_details_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
  
#   # The source ARN is the API Gateway ARN
#   source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
# }

# resource "aws_lambda_permission" "chat_lambda_permission" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.chat_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
  
#   # The source ARN is the API Gateway ARN
#   source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
# }

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

# AGENT-FIXED: CKV_AWS_120 - Enabled API Gateway caching with configurable cache cluster size
# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for API Gateway stage
# AGENT-FIXED: CKV2_AWS_51 - Added client certificate for mutual TLS authentication
# TODO: CKV_AWS_76 - API Gateway stage requires access logging configuration
# Resource: aws_api_gateway_stage.prod
# Reason: Requires a CloudWatch log group to be created and proper IAM permissions for API Gateway to write logs
# Fix: To enable access logging:
#   1. Create a CloudWatch log group resource (e.g., aws_cloudwatch_log_group.api_gateway_logs)
#   2. Create an IAM role with permissions for API Gateway to write to CloudWatch Logs
#   3. Add access_log_settings block to this stage with:
#      - destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
#      - format = "$context.requestId" (or your preferred log format)
# TODO: CKV2_AWS_4 - API Gateway stage requires logging level to be defined
# Resource: aws_api_gateway_stage.prod
# Reason: Requires creating an aws_api_gateway_method_settings resource and a CloudWatch log group with proper IAM permissions
# Fix: To define logging level:
#   1. Create a CloudWatch log group for API Gateway execution logs
#   2. Create an IAM role allowing API Gateway to write to CloudWatch Logs
#   3. Add an aws_api_gateway_method_settings resource:
#      - method_path = "*/*" (for all methods)
#      - settings { logging_level = "ERROR" or "INFO" }
# TODO: CKV2_AWS_29 - Public API Gateway should be protected by AWS WAF
# Resource: aws_api_gateway_stage.prod
# Reason: Requires creating a WAFv2 Web ACL with organization-specific security rules and rate limiting policies
# Fix: To protect the API Gateway with WAF:
#   1. Create an aws_wafv2_web_acl resource with scope = "REGIONAL"
#   2. Define appropriate WAF rules based on your security requirements:
#      - Rate limiting rules to prevent DDoS attacks
#      - IP-based allow/deny lists
#      - Geo-blocking rules if needed
#      - SQL injection and XSS protection rules
#   3. Create an aws_wafv2_web_acl_association resource linking the WAF ACL to the API Gateway stage ARN
#   4. Example:
#      resource "aws_wafv2_web_acl_association" "api_gateway_waf" {
#        resource_arn = aws_api_gateway_stage.prod.arn
#        web_acl_arn  = aws_wafv2_web_acl.example.arn
#      }
# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  # Enable X-Ray tracing
  xray_tracing_enabled = true

  # Enable cache cluster (users can set cache size via variable)
  cache_cluster_enabled = var.enable_cache_cluster
  cache_cluster_size    = var.cache_cluster_size

  # Enable client certificate for mutual TLS
  client_certificate_id = aws_api_gateway_client_certificate.api_cert.id
}

# Create Lambda function zip files
# data "archive_file" "user_details_lambda_zip" {
#   type        = "zip"
#   source_file = "${var.lambda_source_dir}/user_details.py"
#   output_path = "${path.module}/user_details_lambda.zip"
# }

# data "archive_file" "chat_lambda_zip" {
#   type        = "zip"
#   source_file = "${var.lambda_source_dir}/ai_chat.py"
#   output_path = "${path.module}/chat_lambda.zip"
# }
