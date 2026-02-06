# CORS module for API Gateway resources

# TODO: CKV2_AWS_53 - API Gateway request validation is not enabled
# Resource: aws_api_gateway_method.options
# Reason: OPTIONS methods for CORS preflight requests should NOT have strict validation as they are simple browser-initiated checks that follow a standardized protocol. Adding validation could break CORS functionality and prevent legitimate browser requests. This is an intentional design decision for CORS compatibility.
# Fix: If your organization's security policy requires validation even for CORS preflight requests (uncommon and not recommended):
#   1. Create a request validator resource that only validates parameters, not body:
#      resource "aws_api_gateway_request_validator" "cors_validator" {
#        name                        = "cors-options-validator"
#        rest_api_id                 = var.api_id
#        validate_request_body       = false  # OPTIONS method has no body
#        validate_request_parameters = true   # Can validate CORS headers if absolutely necessary
#      }
#   2. Define request parameters for CORS headers (optional and not recommended):
#      request_parameters = {
#        "method.request.header.Origin"                        = false
#        "method.request.header.Access-Control-Request-Method" = false
#        "method.request.header.Access-Control-Request-Headers" = false
#      }
#   3. Add request_validator_id to this method:
#      request_validator_id = aws_api_gateway_request_validator.cors_validator.id
#   4. IMPORTANT: Thoroughly test CORS functionality from browsers after implementation
#   5. CAUTION: This is NOT a recommended practice and may cause CORS failures
#   6. Industry Best Practice: CORS OPTIONS methods are typically left without validation to ensure maximum compatibility with all browsers and prevent blocking legitimate preflight requests
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
