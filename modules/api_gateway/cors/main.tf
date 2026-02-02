# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation not configured for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods for CORS preflight requests typically don't require validation as:
#         - They are MOCK integrations with no backend processing
#         - They don't accept request bodies or parameters
#         - They are used solely for browser CORS preflight checks
#         However, to satisfy security requirements, a request validator should be referenced.
#         This validator should be created at the API Gateway level (parent module) to avoid
#         duplication when multiple CORS modules are used for different resources.
# Fix: To remediate this finding:
#   1. Add a variable to accept the request validator ID from parent module:
#      variable "request_validator_id" {
#        description = "ID of the request validator to use for API methods"
#        type        = string
#        default     = ""
#      }
#   2. Add the request_validator_id to the OPTIONS method:
#      resource "aws_api_gateway_method" "options" {
#        rest_api_id          = var.api_id
#        resource_id          = var.resource_id
#        http_method          = "OPTIONS"
#        authorization        = "NONE"
#        request_validator_id = var.request_validator_id != "" ? var.request_validator_id : null
#      }
#   3. In the parent module, pass the validator ID when calling this CORS module:
#      module "cors_user" {
#        source                = "./cors"
#        api_id                = aws_api_gateway_rest_api.api.id
#        resource_id           = aws_api_gateway_resource.user.id
#        authorizer_id         = aws_api_gateway_authorizer.cognito.id
#        request_validator_id  = aws_api_gateway_request_validator.validator.id
#      }
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
