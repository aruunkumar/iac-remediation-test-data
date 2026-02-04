# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Enable DNSSEC signing for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires KMS key in us-east-1 region and careful operational planning
# Fix: To enable DNSSEC signing:
#   1. Create a KMS key in us-east-1 region with customer_master_key_spec = "ECC_NIST_P256"
#   2. Configure KMS key policy to allow dnssec-route53.amazonaws.com service access
#   3. Create aws_route53_key_signing_key resource with the KMS key ARN
#   4. Create aws_route53_hosted_zone_dnssec resource with signing_status = "SIGNING"
#   5. Update parent zone (domain registrar) with DS records from the key signing key
#   6. Note: KMS key must be in us-east-1 regardless of your primary region
#   7. Example:
#      resource "aws_kms_key" "dnssec" {
#        provider = aws.us-east-1
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = <see AWS provider docs for proper policy>
#      }
#      resource "aws_route53_key_signing_key" "example" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "dnssec-ksk"
#      }
#      resource "aws_route53_hosted_zone_dnssec" "example" {
#        depends_on     = [aws_route53_key_signing_key.example]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }

# TODO: CKV2_AWS_39 - Enable DNS query logging for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires CloudWatch log group and resource policy in us-east-1 region
# Fix: To enable DNS query logging:
#   1. Create CloudWatch log group in us-east-1 region with name pattern "/aws/route53/${var.domain_name}"
#   2. Create CloudWatch log resource policy to allow route53.amazonaws.com to write logs
#   3. Create aws_route53_query_log resource linking zone to log group
#   4. Note: Log group must be in us-east-1 regardless of your primary region
#   5. Note: This is only supported for public hosted zones
#   6. Consider retention_in_days for log group to manage costs
#   7. Example:
#      provider "aws" {
#        alias  = "us-east-1"
#        region = "us-east-1"
#      }
#      resource "aws_cloudwatch_log_group" "route53_query_logs" {
#        provider          = aws.us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30
#      }
#      data "aws_iam_policy_document" "route53_query_logging_policy" {
#        statement {
#          actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
#          resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#          principals {
#            identifiers = ["route53.amazonaws.com"]
#            type        = "Service"
#          }
#        }
#      }
#      resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
#        provider        = aws.us-east-1
#        policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#        policy_name     = "route53-query-logging-policy"
#      }
#      resource "aws_route53_query_log" "example" {
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#      }

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
