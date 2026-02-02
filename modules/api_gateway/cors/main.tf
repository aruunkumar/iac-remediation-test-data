# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway request validation is not enabled for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: This is a CORS preflight OPTIONS method which is automatically sent by browsers. Adding strict request validation could break CORS functionality. OPTIONS methods for CORS typically don't have request bodies or parameters that need validation, as they are simple preflight requests designed to check if the actual request is safe to send. Enabling validation may cause CORS preflight requests to fail.
# Fix: If request validation is required for this OPTIONS method, consider the following:
#   1. Create a request validator resource (or reference an existing one):
#      resource "aws_api_gateway_request_validator" "cors_validator" {
#        name                        = "cors-options-validator"
#        rest_api_id                 = var.api_id
#        validate_request_body       = false  # OPTIONS methods typically don't have bodies
#        validate_request_parameters = false  # Preflight requests don't require parameter validation
#      }
#   2. Add request_validator_id to this OPTIONS method:
#      request_validator_id = aws_api_gateway_request_validator.cors_validator.id
#   3. IMPORTANT: Test thoroughly after implementation to ensure CORS preflight requests still work correctly
#   4. Consider that for CORS OPTIONS methods, validation is often unnecessary and may cause compatibility issues
#   5. If you need to validate other methods (GET, POST, PUT, DELETE), add validators to those methods instead

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
