# Route53 Module

This module creates a Route 53 hosted zone with security features including DNS query logging.

## Provider Requirements

⚠️ **IMPORTANT**: This module requires an AWS provider alias for the `us-east-1` region to support Route 53 query logging (AWS requirement).

Add the following to your root module or wherever you're calling this module:

```hcl
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
```

## Usage

```hcl
module "route53" {
  source = "./modules/route53"

  domain_name              = "example.com"
  query_log_retention_days = 7
  environment              = "production"

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

## Security Features

### DNS Query Logging (CKV2_AWS_39) ✅ ENABLED
- CloudWatch log group created in us-east-1 (AWS requirement)
- Query logs capture all DNS queries to the hosted zone
- Configurable retention period (default: 7 days)
- Helps with security monitoring and troubleshooting

### DNSSEC Signing (CKV2_AWS_38) ⚠️ REQUIRES MANUAL SETUP
DNSSEC is not automatically enabled due to complexity and risk. See the TODO comment in main.tf for implementation steps.

## Variables

- `domain_name` (required): The domain name for the hosted zone
- `query_log_retention_days` (optional): Number of days to retain query logs. Default: 7
- `environment` (optional): Environment name for tagging. Default: "production"

## Outputs

- `hosted_zone_id`: The ID of the hosted zone
- `supernova_role_arn`: The ARN of the SuperNova role
