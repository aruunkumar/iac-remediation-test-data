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

# AGENT-FIXED: CKV_AWS_237 - Added lifecycle block with create_before_destroy to prevent API downtime during updates
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

# TODO: CKV2_AWS_53 - Ensure AWS API gateway request is validated
# Resource: module.api_gateway.aws_api_gateway_method.user_get
# Reason: Requires request validator resource and API schema/model definition based on API contract
# Fix: 1. Create request validator:
#      resource "aws_api_gateway_request_validator" "validator" {
#        rest_api_id                 = aws_api_gateway_rest_api.api.id
#        name                        = "request-validator"
#        validate_request_body       = true
#        validate_request_parameters = true
#      }
#      2. Define request model for GET (typically query parameters):
#      resource "aws_api_gateway_model" "user_get_model" {
#        rest_api_id  = aws_api_gateway_rest_api.api.id
#        name         = "UserGetModel"
#        content_type = "application/json"
#        schema = jsonencode({
#          type = "object"
#          # Define schema based on your API requirements
#        })
#      }
#      3. Add to method resource below:
#      request_validator_id = aws_api_gateway_request_validator.validator.id
#      request_parameters = {
#        "method.request.querystring.userId" = true  # Example required param
#      }

# Create API methods for user resource
resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "GET"
  authorization =  aws_api_gateway_authorizer.cognito.id
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

# TODO: CKV_AWS_120 - Ensure API Gateway caching is enabled
# Resource: module.api_gateway.aws_api_gateway_stage.prod
# Reason: Requires business decision on cache cluster size (0.5-237 GB) with significant cost implications and TTL configuration
# Fix: Add to stage resource:
#      cache_cluster_enabled = true
#      cache_cluster_size    = "0.5"  # Options: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237 GB
#      Optionally add method settings for cache behavior:
#      resource "aws_api_gateway_method_settings" "cache" {
#        rest_api_id = aws_api_gateway_rest_api.api.id
#        stage_name  = aws_api_gateway_stage.prod.stage_name
#        method_path = "*/*"
#        settings {
#          caching_enabled      = true
#          cache_ttl_in_seconds = 300
#          cache_data_encrypted = true
#        }
#      }

# TODO: CKV_AWS_76 - Ensure API Gateway has Access Logging enabled
# Resource: module.api_gateway.aws_api_gateway_stage.prod
# Reason: Requires CloudWatch log group creation as external dependency
# Fix: 1. Create CloudWatch log group:
#      resource "aws_cloudwatch_log_group" "api_gateway_logs" {
#        name              = "/aws/apigateway/${var.api_name}"
#        retention_in_days = 7
#      }
#      2. Add to stage resource:
#      access_log_settings {
#        destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
#        format = "$context.requestId $context.error.message $context.error.messageString"
#      }

# TODO: CKV2_AWS_4 - Ensure API Gateway stage have logging level defined as appropriate
# Resource: module.api_gateway.aws_api_gateway_stage.prod
# Reason: Requires separate aws_api_gateway_method_settings resource and CloudWatch log group with account-level IAM role
# Fix: 1. Ensure CloudWatch log group exists (see CKV_AWS_76)
#      2. Create method settings resource:
#      resource "aws_api_gateway_method_settings" "logging" {
#        rest_api_id = aws_api_gateway_rest_api.api.id
#        stage_name  = aws_api_gateway_stage.prod.stage_name
#        method_path = "*/*"
#        settings {
#          metrics_enabled    = true
#          logging_level      = "INFO"  # Options: OFF, ERROR, INFO
#          data_trace_enabled = false
#        }
#      }
#      Note: Account-level IAM role required for API Gateway to write to CloudWatch

# TODO: CKV2_AWS_51 - Ensure AWS API Gateway endpoints uses client certificate authentication
# Resource: module.api_gateway.aws_api_gateway_stage.prod
# Reason: Requires client certificate resource creation and backend system configuration to validate certificates
# Fix: 1. Create client certificate:
#      resource "aws_api_gateway_client_certificate" "cert" {
#        description = "Client certificate for API Gateway backend authentication"
#      }
#      2. Add to stage resource below:
#      client_certificate_id = aws_api_gateway_client_certificate.cert.id
#      Note: Backend systems (Lambda, HTTP endpoints) must be configured to validate the 
#            client certificate presented by API Gateway for mutual TLS authentication

# TODO: CKV2_AWS_29 - Ensure public API gateway are protected by WAF
# Resource: module.api_gateway.aws_api_gateway_stage.prod
# Reason: Requires WAF Web ACL creation with security rules based on organizational threat model and compliance requirements
# Fix: 1. Create WAF Web ACL (AWS WAFv2 for regional API Gateway):
#      resource "aws_wafv2_web_acl" "api_waf" {
#        name  = "${var.api_name}-waf"
#        scope = "REGIONAL"
#        default_action {
#          allow {}
#        }
#        visibility_config {
#          cloudwatch_metrics_enabled = true
#          metric_name               = "${var.api_name}-waf-metrics"
#          sampled_requests_enabled  = true
#        }
#        rule {
#          name     = "RateLimitRule"
#          priority = 1
#          action {
#            block {}
#          }
#          statement {
#            rate_based_statement {
#              limit              = 2000
#              aggregate_key_type = "IP"
#            }
#          }
#          visibility_config {
#            cloudwatch_metrics_enabled = true
#            metric_name               = "RateLimitRule"
#            sampled_requests_enabled  = true
#          }
#        }
#        # Add additional managed rules or custom rules:
#        # - AWS Managed Rules (AWSManagedRulesCommonRuleSet)
#        # - SQL injection protection
#        # - XSS protection
#        # - Geographic restrictions
#        # - IP reputation lists
#      }
#      2. Associate WAF with API Gateway stage:
#      resource "aws_wafv2_web_acl_association" "api_waf_association" {
#        resource_arn = aws_api_gateway_stage.prod.arn
#        web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
#      }

# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for distributed request tracing and performance monitoring
# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  xray_tracing_enabled = true
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
