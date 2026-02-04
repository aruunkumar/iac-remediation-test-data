# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway request validation for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: CORS preflight OPTIONS methods typically don't require request validation
# Fix: Consider the following options based on your requirements:
#   Option 1 (Recommended for CORS): Accept the finding as a false positive
#     - OPTIONS preflight requests are standardized browser behavior
#     - They don't contain application data requiring validation
#     - MOCK integration doesn't process request body or parameters
#     - Adding validation may break legitimate CORS functionality
#   
#   Option 2: Add minimal request validator if organizational policy requires it
#     - Create aws_api_gateway_request_validator with validate_request_parameters = false and validate_request_body = false
#     - Add request_validator_id to the method
#     - Example:
#       resource "aws_api_gateway_request_validator" "cors_validator" {
#         name                        = "cors-options-validator"
#         rest_api_id                 = var.api_id
#         validate_request_body       = false
#         validate_request_parameters = false
#       }
#       # Then add to method: request_validator_id = aws_api_gateway_request_validator.cors_validator.id
#   
#   Option 3: If validation is truly needed (non-standard use case)
#     - Define request_parameters for expected CORS headers
#     - Create validator with validate_request_parameters = true
#     - Note: This may reject valid preflight requests from some browsers

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
