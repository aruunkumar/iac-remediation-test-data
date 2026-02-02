# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway request validation for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: CORS preflight OPTIONS requests typically should not have strict validation as it can break CORS functionality
# Fix: Consider the following options based on your security requirements:
#   Option 1 (Recommended for CORS): Keep OPTIONS method without validation
#     - OPTIONS is a preflight request used by browsers for CORS checks
#     - It typically has no request body or parameters to validate
#     - Adding validation may interfere with legitimate CORS preflight requests
#     - This is the standard approach for CORS-enabled APIs
#   
#   Option 2 (If validation is required): Add minimal validation
#     - Create a request validator that only validates parameters (not body):
#       resource "aws_api_gateway_request_validator" "options_validator" {
#         name                        = "options-validator"
#         rest_api_id                 = var.api_id
#         validate_request_body       = false
#         validate_request_parameters = true
#       }
#     - Add to the method:
#       request_validator_id = aws_api_gateway_request_validator.options_validator.id
#     - Note: This may still impact CORS functionality depending on client behavior
#   
#   Option 3 (Strictest): Add full validation (NOT recommended for OPTIONS)
#     - Create a full request validator:
#       resource "aws_api_gateway_request_validator" "options_validator" {
#         name                        = "options-validator"
#         rest_api_id                 = var.api_id
#         validate_request_body       = true
#         validate_request_parameters = true
#       }
#     - Add to the method:
#       request_validator_id = aws_api_gateway_request_validator.options_validator.id
#     - WARNING: This can break CORS and is not recommended for OPTIONS methods
#   
#   Recommendation: For CORS OPTIONS methods, Option 1 is the industry standard.
#                  Only add validation if your security policy explicitly requires it
#                  and you've tested that it doesn't break CORS for your clients.
#
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
