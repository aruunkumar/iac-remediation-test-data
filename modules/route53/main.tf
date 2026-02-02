# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route53 hosted zone
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: Requires KMS key in us-east-1, key signing key, and DNSSEC configuration with careful planning
# Fix: To enable DNSSEC signing:
#   1. Create or configure a provider alias for us-east-1 region (KMS key must be in us-east-1):
#      provider "aws" {
#        alias  = "us-east-1"
#        region = "us-east-1"
#      }
#   2. Create a KMS key with customer_master_key_spec = "ECC_NIST_P256" and key_usage = "SIGN_VERIFY"
#   3. Configure KMS key policy to allow dnssec-route53.amazonaws.com service to use the key
#   4. Create aws_route53_key_signing_key resource referencing the KMS key
#   5. Create aws_route53_hosted_zone_dnssec resource with signing_status = "SIGNING"
#   6. After Terraform apply, add DS records to parent zone (registrar) to complete DNSSEC chain of trust
#   7. Monitor DNS propagation carefully - improper configuration can cause domain unavailability
#   Note: Disabling DNSSEC later requires waiting for TTL expiration to avoid domain outages
# TODO: CKV2_AWS_39 - DNS query logging is not enabled for Route53 hosted zone
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: Requires CloudWatch log group in us-east-1, log resource policy, and business decisions on retention
# Fix: To enable DNS query logging:
#   1. Create or configure a provider alias for us-east-1 region (log group must be in us-east-1):
#      provider "aws" {
#        alias  = "us-east-1"
#        region = "us-east-1"
#      }
#   2. Create CloudWatch log group in us-east-1: aws_cloudwatch_log_group with name pattern "/aws/route53/${domain_name}"
#   3. Decide on log retention period (e.g., 7, 30, 90 days) based on compliance and cost requirements
#   4. Create CloudWatch log resource policy (aws_cloudwatch_log_resource_policy) allowing route53.amazonaws.com to write logs
#   5. Create aws_route53_query_log resource linking the hosted zone to the log group
#   6. Note: Query logging incurs CloudWatch Logs storage and ingestion costs
#   7. Consider log retention period and archival strategy for cost optimization
resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name

  # Apply a lifecycle policy to retain the hosted zone on destroy
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "supernova_role" {
  name = "Nova-DO-NOT-DELETE"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "nova.aws.internal"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "route53_full_access" {
  role       = aws_iam_role.supernova_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "security_audit" {
  role       = aws_iam_role.supernova_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
