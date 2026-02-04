# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - Request validation is not enabled for API Gateway OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: CORS OPTIONS methods are preflight requests that typically don't require validation, and adding strict validation may break CORS functionality. This decision depends on specific API security requirements.
# Fix: If request validation is required for this OPTIONS method, complete the following steps:
#   1. Create or reference an aws_api_gateway_request_validator resource with:
#      - name = "${var.api_name}-cors-validator"
#      - rest_api_id = var.api_id
#      - validate_request_parameters = true (OPTIONS typically has no body)
#      - validate_request_body = false (OPTIONS preflight has no body)
#   2. Add request_validator_id to aws_api_gateway_method.options:
#      - request_validator_id = aws_api_gateway_request_validator.<validator>.id
#   3. Note: CORS preflight (OPTIONS) requests are typically unauthenticated and simple
#   4. Consider if validation is necessary for your specific use case, as it may interfere with browser CORS handling
#   5. Test thoroughly after enabling to ensure CORS still functions correctly
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
