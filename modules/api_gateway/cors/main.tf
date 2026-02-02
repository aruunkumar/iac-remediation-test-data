# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation is not configured for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods for CORS preflight requests typically don't require request validation
# Fix: Consider whether request validation is appropriate for CORS OPTIONS method:
#   1. CORS OPTIONS (preflight) requests are typically made by browsers before actual requests
#   2. They don't carry request bodies or parameters that need validation
#   3. Adding validation might break CORS functionality for browser-based applications
#   4. If validation is required, create a request validator (or reference existing validator from parent module):
#      - Add request_validator_id parameter to this method
#      - Reference the validator: request_validator_id = var.request_validator_id
#   5. Note: Most CORS implementations intentionally skip validation on OPTIONS for compatibility
#   6. Evaluate based on your specific security requirements and CORS use case
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
