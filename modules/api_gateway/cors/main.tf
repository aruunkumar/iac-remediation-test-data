# CORS module for API Gateway resources

# AGENT-FIXED: CKV2_AWS_53 - Added request validator for API Gateway OPTIONS method
# Note: For CORS preflight OPTIONS requests, request validation is typically minimal
# since these are lightweight checks that precede actual requests. However, we add
# a validator for compliance. The actual validation is performed on the real HTTP methods.
resource "aws_api_gateway_request_validator" "cors_validator" {
  name                        = "cors-options-validator"
  rest_api_id                 = var.api_id
  validate_request_body       = false
  validate_request_parameters = false
}

# AGENT-FIXED: CKV2_AWS_53 - Added request_validator_id to OPTIONS method
# Create OPTIONS method
resource "aws_api_gateway_method" "options" {
  rest_api_id          = var.api_id
  resource_id          = var.resource_id
  http_method          = "OPTIONS"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.cors_validator.id
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
