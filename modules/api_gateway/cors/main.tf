# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway request validation for OPTIONS method
# Resource: aws_api_gateway_method.options
# Reason: CORS OPTIONS methods are MOCK integrations for preflight requests and typically don't require validation
# Fix: If validation is required for compliance:
#   1. Add a request_validator_id variable to this module:
#      variable "request_validator_id" {
#        description = "The ID of the API Gateway request validator"
#        type        = string
#        default     = null
#      }
#   2. Reference the request validator created in the parent module (if it exists)
#   3. Add request_validator_id to the OPTIONS method:
#      request_validator_id = var.request_validator_id
#   4. Note: For CORS OPTIONS methods, validation is typically not needed since:
#      - They are MOCK integrations with no backend processing
#      - Browsers automatically send them for preflight checks
#      - They don't accept request bodies or parameters to validate
#      - Over-strict validation could break CORS functionality
#   5. Alternative: Create a minimal validator that only validates parameters:
#      resource "aws_api_gateway_request_validator" "options_validator" {
#        name                        = "cors-options-validator"
#        rest_api_id                 = var.api_id
#        validate_request_body       = false
#        validate_request_parameters = false
#      }
#      Then reference it: request_validator_id = aws_api_gateway_request_validator.options_validator.id
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
