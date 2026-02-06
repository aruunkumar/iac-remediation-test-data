# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Add request validation to API Gateway OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: Adding request validation to CORS preflight OPTIONS methods may break CORS functionality and provide minimal security benefit
# Fix: To add request validation (evaluate if appropriate for your use case):
#   1. Create a request validator resource:
#     resource "aws_api_gateway_request_validator" "cors_validator" {
#       name                        = "cors-options-validator"
#       rest_api_id                 = var.api_id
#       validate_request_body       = false  # OPTIONS typically don't have bodies
#       validate_request_parameters = true   # Can validate headers if needed
#     }
#   2. Add request_validator_id to the OPTIONS method:
#     request_validator_id = aws_api_gateway_request_validator.cors_validator.id
#   3. Consider if validation is necessary for OPTIONS preflight requests:
#      - OPTIONS requests are typically simple preflight requests
#      - They don't contain sensitive data or request bodies
#      - Validation may interfere with CORS functionality
#      - Most CORS implementations don't validate OPTIONS methods
#   4. Alternative: Accept this as a false positive for CORS OPTIONS methods
#      and focus validation on actual API methods (GET, POST, PUT, DELETE)

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