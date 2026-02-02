# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation not configured for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods are CORS preflight requests that typically have no body or parameters to validate
# Fix: Evaluate if request validation is needed for this CORS OPTIONS endpoint:
#   1. OPTIONS requests for CORS are typically simple preflight requests with no request body
#   2. They have minimal or no query parameters and use standard CORS headers
#   3. Adding strict validation may break CORS functionality for legitimate clients
#   4. If validation is required for compliance:
#      - Create aws_api_gateway_request_validator resource with validate_request_parameters = true
#      - Set request_validator_id on this method to reference the validator
#      - Do NOT enable validate_request_body as OPTIONS should not have a body
#   5. Alternative: Accept this as a false positive since CORS OPTIONS is a special case
#   6. Consider if your API's CORS configuration requires validation of Origin headers
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
