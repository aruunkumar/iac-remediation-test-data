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

# Create API Gateway
# AGENT-FIXED: CKV_AWS_237 - Added create_before_destroy lifecycle policy
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

# TODO: CKV2_AWS_53 - Enable API Gateway request validation
# Resource: aws_api_gateway_method.user_get
# Reason: Request validation requires defining request models and validators specific to API contract. Business logic decision on validation rules.
# Fix: Create request validator and model, then reference in method configuration:
#
# 1. Create request validator:
#    resource "aws_api_gateway_request_validator" "validator" {
#      name                        = "request-validator"
#      rest_api_id                 = aws_api_gateway_rest_api.api.id
#      validate_request_body       = true
#      validate_request_parameters = true
#    }
#
# 2. Define request/response models (JSON Schema):
#    resource "aws_api_gateway_model" "user_model" {
#      rest_api_id  = aws_api_gateway_rest_api.api.id
#      name         = "UserModel"
#      description  = "User request/response model"
#      content_type = "application/json"
#      schema = jsonencode({
#        type = "object"
#        required = ["userId"]
#        properties = {
#          userId = { type = "string" }
#          name   = { type = "string" }
#          email  = { type = "string", format = "email" }
#        }
#      })
#    }
#
# 3. Update method to use validator:
#    resource "aws_api_gateway_method" "user_get" {
#      rest_api_id          = aws_api_gateway_rest_api.api.id
#      resource_id          = aws_api_gateway_resource.user.id
#      http_method          = "GET"
#      authorization        = aws_api_gateway_authorizer.cognito.id
#      request_validator_id = aws_api_gateway_request_validator.validator.id
#      request_parameters = {
#        "method.request.querystring.userId" = true
#      }
#    }

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

# TODO: CKV_AWS_76, CKV2_AWS_4 - Enable API Gateway access logging with appropriate log level
# Resource: aws_api_gateway_stage.prod
# Reason: Requires CloudWatch Log Group and IAM role for API Gateway logging. Multi-resource coordination needed.
# Fix: Create the following resources and update the stage configuration:
#
# 1. Create CloudWatch Log Group:
#    resource "aws_cloudwatch_log_group" "api_gateway_logs" {
#      name              = "/aws/apigateway/${var.api_name}"
#      retention_in_days = 7  # Adjust as needed
#    }
#
# 2. Create IAM role for API Gateway logging:
#    resource "aws_iam_role" "api_gateway_cloudwatch_role" {
#      name = "api-gateway-cloudwatch-role"
#      assume_role_policy = jsonencode({
#        Version = "2012-10-17"
#        Statement = [{
#          Action = "sts:AssumeRole"
#          Effect = "Allow"
#          Principal = { Service = "apigateway.amazonaws.com" }
#        }]
#      })
#    }
#
#    resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
#      role       = aws_iam_role.api_gateway_cloudwatch_role.name
#      policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
#    }
#
#    resource "aws_api_gateway_account" "api_account" {
#      cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
#    }
#
# 3. Update the stage to enable access logging:
#    access_log_settings {
#      destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
#      format = "$context.requestId $context.extendedRequestId $context.identity.sourceIp $context.requestTime"
#    }
#
# 4. Add method settings for logging level:
#    resource "aws_api_gateway_method_settings" "prod_settings" {
#      rest_api_id = aws_api_gateway_rest_api.api.id
#      stage_name  = aws_api_gateway_stage.prod.stage_name
#      method_path = "*/*"
#      settings {
#        logging_level      = "INFO"  # Choose INFO or ERROR based on requirements
#        data_trace_enabled = true
#        metrics_enabled    = true
#      }
#    }

# TODO: CKV_AWS_120 - Enable API Gateway caching
# Resource: aws_api_gateway_stage.prod
# Reason: Caching has cost implications and requires business decisions on cache size (0.5GB to 237GB) and TTL.
# Fix: Add cache_cluster_enabled and cache_cluster_size to the stage. Example:
#    resource "aws_api_gateway_stage" "prod" {
#      deployment_id        = aws_api_gateway_deployment.deployment.id
#      rest_api_id          = aws_api_gateway_rest_api.api.id
#      stage_name           = "prod"
#      cache_cluster_enabled = true
#      cache_cluster_size   = "0.5"  # Options: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237 (GB)
#      xray_tracing_enabled = true
#    }
#
#    Then configure method-level caching with aws_api_gateway_method_settings:
#    resource "aws_api_gateway_method_settings" "prod_cache_settings" {
#      rest_api_id = aws_api_gateway_rest_api.api.id
#      stage_name  = aws_api_gateway_stage.prod.stage_name
#      method_path = "*/*"
#      settings {
#        caching_enabled      = true
#        cache_ttl_in_seconds = 300  # Adjust TTL as needed (0-3600 seconds)
#        cache_data_encrypted = true
#      }
#    }

# TODO: CKV2_AWS_51 - Enable client certificate authentication for API Gateway
# Resource: aws_api_gateway_stage.prod
# Reason: Requires generating/importing client certificates and distributing to authorized clients. Organizational security decision.
# Fix: Create and configure client certificate for mutual TLS authentication:
#
# 1. Generate or import client certificate:
#    resource "aws_api_gateway_client_certificate" "client_cert" {
#      description = "Client certificate for API Gateway"
#    }
#
# 2. Update stage to use client certificate:
#    resource "aws_api_gateway_stage" "prod" {
#      deployment_id         = aws_api_gateway_deployment.deployment.id
#      rest_api_id           = aws_api_gateway_rest_api.api.id
#      stage_name            = "prod"
#      xray_tracing_enabled  = true
#      client_certificate_id = aws_api_gateway_client_certificate.client_cert.id
#    }
#
# 3. Distribute the certificate to authorized API clients
# 4. Configure backend systems to validate client certificates

# TODO: CKV2_AWS_29 - Protect public API Gateway with AWS WAF
# Resource: aws_api_gateway_stage.prod
# Reason: WAF setup requires defining security rules, rate limits, and IP filtering. Multi-resource coordination and cost implications.
# Fix: Create WAF WebACL and associate with API Gateway stage:
#
# 1. Create WAF WebACL with appropriate rules:
#    resource "aws_wafv2_web_acl" "api_gateway_waf" {
#      name  = "${var.api_name}-waf"
#      scope = "REGIONAL"
#      default_action {
#        allow {}
#      }
#      rule {
#        name     = "RateLimitRule"
#        priority = 1
#        action {
#          block {}
#        }
#        statement {
#          rate_based_statement {
#            limit              = 2000
#            aggregate_key_type = "IP"
#          }
#        }
#        visibility_config {
#          cloudwatch_metrics_enabled = true
#          metric_name                = "RateLimitRule"
#          sampled_requests_enabled   = true
#        }
#      }
#      # Add more rules as needed (SQL injection, XSS, etc.)
#      visibility_config {
#        cloudwatch_metrics_enabled = true
#        metric_name                = "APIGatewayWAF"
#        sampled_requests_enabled   = true
#      }
#    }
#
# 2. Associate WAF with API Gateway stage:
#    resource "aws_wafv2_web_acl_association" "api_gateway_waf_association" {
#      resource_arn = aws_api_gateway_stage.prod.arn
#      web_acl_arn  = aws_wafv2_web_acl.api_gateway_waf.arn
#    }

# Create API Gateway stage
# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id        = aws_api_gateway_deployment.deployment.id
  rest_api_id          = aws_api_gateway_rest_api.api.id
  stage_name           = "prod"
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
