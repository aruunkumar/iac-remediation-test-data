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
# AGENT-FIXED: CKV_AWS_237 - Added lifecycle block with create_before_destroy to ensure safe replacement of API Gateway
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

# AGENT-FIXED: CKV2_AWS_53 - Created request validator to validate API Gateway requests
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "${var.api_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.api.id
  validate_request_body       = true
  validate_request_parameters = true
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

# AGENT-FIXED: CKV2_AWS_53 - Added request_validator_id to enable request validation
# Create API methods for user resource
resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "GET"
  authorization =  aws_api_gateway_authorizer.cognito.id
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

# TODO: CKV_AWS_76 - API Gateway Access Logging is not enabled
# Resource: aws_api_gateway_stage.prod
# Reason: Enabling access logging requires creating a CloudWatch Log Group and IAM role for API Gateway to write logs, which may impact existing infrastructure and costs
# Fix: To remediate this finding:
#   1. Create a CloudWatch Log Group for API Gateway access logs:
#      resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
#        name              = "/aws/apigateway/${var.api_name}/access-logs"
#        retention_in_days = 7  # Adjust retention as needed
#      }
#   2. Create an IAM role for API Gateway to write to CloudWatch Logs (if not already exists):
#      resource "aws_iam_role" "api_gateway_cloudwatch_role" {
#        name = "api-gateway-cloudwatch-role"
#        assume_role_policy = jsonencode({
#          Version = "2012-10-17"
#          Statement = [{
#            Action = "sts:AssumeRole"
#            Effect = "Allow"
#            Principal = { Service = "apigateway.amazonaws.com" }
#          }]
#        })
#      }
#      resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
#        role       = aws_iam_role.api_gateway_cloudwatch_role.name
#        policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
#      }
#   3. Set the CloudWatch role ARN in API Gateway account settings:
#      resource "aws_api_gateway_account" "main" {
#        cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
#      }
#   4. Add access_log_settings block to this stage:
#      access_log_settings {
#        destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
#        format = "$context.requestId $context.extendedRequestId $context.identity.sourceIp $context.requestTime $context.routeKey $context.status"
#      }

# TODO: CKV2_AWS_4 - API Gateway stage logging level is not defined
# Resource: aws_api_gateway_stage.prod
# Reason: Setting logging level requires creating aws_api_gateway_method_settings resource and proper CloudWatch configuration, which depends on the access logging setup (CKV_AWS_76)
# Fix: To remediate this finding (after fixing CKV_AWS_76):
#   1. Create aws_api_gateway_method_settings resource to define logging level:
#      resource "aws_api_gateway_method_settings" "all" {
#        rest_api_id = aws_api_gateway_rest_api.api.id
#        stage_name  = aws_api_gateway_stage.prod.stage_name
#        method_path = "*/*"
#        settings {
#          metrics_enabled = true
#          logging_level   = "ERROR"  # Options: OFF, ERROR, INFO
#        }
#      }
#   2. Ensure CloudWatch Log Group and IAM role are configured (from CKV_AWS_76)

# TODO: CKV2_AWS_51 - API Gateway endpoints should use client certificate authentication
# Resource: aws_api_gateway_stage.prod
# Reason: Requires creating and managing client certificates, which is an organizational security decision that may impact backend integration and certificate lifecycle management
# Fix: To remediate this finding:
#   1. Create an API Gateway Client Certificate:
#      resource "aws_api_gateway_client_certificate" "api_cert" {
#        description = "Client certificate for ${var.api_name}"
#        tags = {
#          Name = "${var.api_name}-client-cert"
#        }
#      }
#   2. Add the client_certificate_id to the stage (below in the stage resource):
#      client_certificate_id = aws_api_gateway_client_certificate.api_cert.id
#   3. Configure your backend services to validate the client certificate
#   4. Implement certificate rotation procedures before expiration (certificates expire after ~10 years)

# TODO: CKV2_AWS_29 - Public API Gateway should be protected by WAF
# Resource: aws_api_gateway_stage.prod
# Reason: WAF configuration is organization-specific and requires careful planning of rules, rate limiting, and security policies. It also has cost implications.
# Fix: To remediate this finding:
#   1. Create a WAFv2 Web ACL with appropriate rules (or reference an existing one):
#      resource "aws_wafv2_web_acl" "api_waf" {
#        name  = "${var.api_name}-waf"
#        scope = "REGIONAL"
#        default_action {
#          allow {}
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
#            metric_name                = "RateLimitRule"
#            sampled_requests_enabled   = true
#          }
#        }
#        visibility_config {
#          cloudwatch_metrics_enabled = true
#          metric_name                = "${var.api_name}-waf-metric"
#          sampled_requests_enabled   = true
#        }
#      }
#   2. Associate the Web ACL with the API Gateway stage:
#      resource "aws_wafv2_web_acl_association" "api_waf_association" {
#        resource_arn = aws_api_gateway_stage.prod.arn
#        web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
#      }
#   3. Consider implementing additional WAF rules for common threats:
#      - SQL injection protection
#      - XSS protection
#      - Geographic restrictions
#      - IP reputation lists
#      - Custom rules based on your application needs

# AGENT-FIXED: CKV_AWS_120 - Enabled API Gateway caching with default cache size of 0.5GB
# AGENT-FIXED: CKV_AWS_73 - Enabled X-Ray tracing for API Gateway stage to track and analyze requests
# Create API Gateway stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
  
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
  
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
