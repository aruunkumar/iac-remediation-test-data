# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway method requires request validation
# Resource: aws_api_gateway_method.options
# Reason: This is a CORS OPTIONS preflight method that typically doesn't require request validation. Adding validation might interfere with CORS functionality. The request validator should be created at the API level by the module caller if needed, not within this reusable CORS module.
# Fix: To remediate this issue (only if request validation is required for your use case):
#   1. Create an aws_api_gateway_request_validator resource at the API level (not in this module):
#      resource "aws_api_gateway_request_validator" "validator" {
#        name                        = "request-validator"
#        rest_api_id                 = var.api_id
#        validate_request_body       = false  # OPTIONS methods don't have a body
#        validate_request_parameters = true   # Can validate headers if needed
#      }
#   2. Pass the validator ID as a variable to this module
#   3. Add request_validator_id to the method below:
#      request_validator_id = var.request_validator_id
#   4. Note: For CORS OPTIONS methods, validation is usually not necessary and may cause issues
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
