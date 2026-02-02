# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation not configured for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods for CORS are pre-flight requests with MOCK integration that don't process actual request data
# Fix: While request validation can be added, it's typically unnecessary for CORS OPTIONS methods because:
#   1. OPTIONS is a pre-flight CORS check with no request body or meaningful parameters
#   2. The integration is MOCK type, returning a fixed response without processing input
#   3. Adding validation to OPTIONS methods is generally considered over-engineering
#   However, if validation is required for compliance, implement one of these approaches:
#   
#   Option A: Add request_validator_id variable and pass validator from parent module
#     1. Add to variables.tf:
#        variable "request_validator_id" {
#          description = "ID of the API Gateway request validator"
#          type        = string
#          default     = null
#        }
#     2. Update the OPTIONS method:
#        resource "aws_api_gateway_method" "options" {
#          rest_api_id          = var.api_id
#          resource_id          = var.resource_id
#          http_method          = "OPTIONS"
#          authorization        = "NONE"
#          request_validator_id = var.request_validator_id
#        }
#     3. Update parent module to pass validator ID when calling this module
#   
#   Option B: Create a minimal validator within this module
#        resource "aws_api_gateway_request_validator" "options_validator" {
#          name                        = "cors-options-validator"
#          rest_api_id                 = var.api_id
#          validate_request_body       = false
#          validate_request_parameters = false
#        }
#        Then reference it in the OPTIONS method with: request_validator_id = aws_api_gateway_request_validator.options_validator.id
#   
#   Note: Most security practitioners consider CORS OPTIONS methods exempt from validation requirements
# Create OPTIONS method
resource "aws_api_gateway_method" "options" {
  rest_api_id   = var.api_id
  resource_id   = var.resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Create OPTIONS method response
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = var.api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Create OPTIONS integration
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = var.api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Create OPTIONS integration response
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = var.api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
