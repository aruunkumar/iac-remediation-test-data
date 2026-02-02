# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation is not configured for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods are CORS preflight requests sent automatically by browsers and don't contain request body or parameters requiring validation. Adding validation to OPTIONS can break CORS functionality.
# Fix: If validation is required for compliance:
#   1. Pass a request_validator_id variable from the parent module
#   2. Add request_validator_id parameter to this module's variables
#   3. Add request_validator_id = var.request_validator_id to the method below
#   Note: For standard CORS preflight requests, validation is not recommended as:
#     - OPTIONS requests have no body or parameters to validate
#     - Validation could interfere with browser preflight behavior
#     - The integration type is MOCK (no backend processing)
#   Alternative: Create a minimal validator that only validates parameters (not body):
#     resource "aws_api_gateway_request_validator" "options_validator" {
#       name                        = "options-validator"
#       rest_api_id                 = var.api_id
#       validate_request_body       = false
#       validate_request_parameters = true
#     }
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
