# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Enabling DNSSEC requires complex setup with KMS keys and carries risk of domain unavailability if misconfigured
# Fix: To enable DNSSEC signing:
#   1. Create a KMS key in us-east-1 region with specific configuration:
#      - customer_master_key_spec = "ECC_NIST_P256"
#      - key_usage = "SIGN_VERIFY"
#      - deletion_window_in_days = 7 (or higher for production)
#   2. Configure KMS key policy to allow Route53 DNSSEC service access (see example below)
#   3. Create aws_route53_key_signing_key resource referencing the KMS key
#   4. Create aws_route53_hosted_zone_dnssec resource to enable DNSSEC
#   5. IMPORTANT: After enabling, update parent domain with DS records
#   6. WARNING: Disabling DNSSEC improperly can cause domain unavailability
#   Example configuration:
#     resource "aws_kms_key" "dnssec" {
#       provider                 = aws.us-east-1
#       customer_master_key_spec = "ECC_NIST_P256"
#       deletion_window_in_days  = 7
#       key_usage                = "SIGN_VERIFY"
#       policy = jsonencode({
#         Statement = [
#           {
#             Action = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign", "kms:Verify"]
#             Effect = "Allow"
#             Principal = { Service = "dnssec-route53.amazonaws.com" }
#             Resource = "*"
#             Sid = "Allow Route 53 DNSSEC Service"
#           },
#           {
#             Action = "kms:*"
#             Effect = "Allow"
#             Principal = { AWS = "arn:aws:iam::ACCOUNT_ID:root" }
#             Resource = "*"
#             Sid = "Enable IAM User Permissions"
#           }
#         ]
#         Version = "2012-10-17"
#       })
#     }
#     resource "aws_route53_key_signing_key" "dnssec" {
#       hosted_zone_id             = aws_route53_zone.hosted_zone.id
#       key_management_service_arn = aws_kms_key.dnssec.arn
#       name                       = "dnssec-ksk"
#     }
#     resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#       depends_on     = [aws_route53_key_signing_key.dnssec]
#       hosted_zone_id = aws_route53_key_signing_key.dnssec.hosted_zone_id
#     }
# TODO: CKV2_AWS_39 - DNS query logging is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch log group in us-east-1 region and log resource policy setup
# Fix: To enable DNS query logging:
#   1. Create CloudWatch log group in us-east-1 region (required by Route53)
#   2. Create CloudWatch log resource policy to allow Route53 to write logs
#   3. Create aws_route53_query_log resource to enable logging
#   4. Consider log retention period and storage costs
#   Example configuration:
#     provider "aws" {
#       alias  = "us-east-1"
#       region = "us-east-1"
#     }
#     resource "aws_cloudwatch_log_group" "route53_query_log" {
#       provider          = aws.us-east-1
#       name              = "/aws/route53/${var.domain_name}"
#       retention_in_days = 30
#     }
#     data "aws_iam_policy_document" "route53_query_log_policy" {
#       statement {
#         actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
#         resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#         principals {
#           identifiers = ["route53.amazonaws.com"]
#           type        = "Service"
#         }
#       }
#     }
#     resource "aws_cloudwatch_log_resource_policy" "route53_query_log_policy" {
#       provider        = aws.us-east-1
#       policy_document = data.aws_iam_policy_document.route53_query_log_policy.json
#       policy_name     = "route53-query-logging-policy"
#     }
#     resource "aws_route53_query_log" "query_log" {
#       depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_log_policy]
#       cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
#       zone_id                  = aws_route53_zone.hosted_zone.zone_id
#     }
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
