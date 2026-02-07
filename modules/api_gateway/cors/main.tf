# CORS module for API Gateway resources

# AGENT-FIXED: CKV2_AWS_53 - Created request validator to validate API Gateway requests
# Create request validator for OPTIONS method
resource "aws_api_gateway_request_validator" "options_validator" {
  name                        = "cors-options-validator"
  rest_api_id                 = var.api_id
  validate_request_body       = false
  validate_request_parameters = true
}

# AGENT-FIXED: CKV2_AWS_53 - Added request validator to OPTIONS method for request validation
# Create OPTIONS method
resource "aws_api_gateway_method" "options" {
  rest_api_id          = var.api_id
  resource_id          = var.resource_id
  http_method          = "OPTIONS"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.options_validator.id
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