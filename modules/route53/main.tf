# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing not enabled for Route 53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC configuration requires multiple resources with specific regional constraints and operational considerations
# Fix: To enable DNSSEC signing for this hosted zone:
#   1. Create a KMS key in us-east-1 region with ECC_NIST_P256 spec for SIGN_VERIFY usage
#   2. Configure KMS key policy to allow Route 53 DNSSEC service to use the key
#   3. Create aws_route53_key_signing_key resource referencing the KMS key ARN
#   4. Create aws_route53_hosted_zone_dnssec resource with signing_status = "SIGNING"
#   5. Update parent domain's DS records with the delegation signer information
#   6. Example implementation:
#      # Ensure this uses us-east-1 region
#      resource "aws_kms_key" "dnssec" {
#        provider                 = aws.us-east-1  # Must be us-east-1
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = jsonencode({
#          Statement = [
#            {
#              Action = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign"]
#              Effect = "Allow"
#              Principal = { Service = "dnssec-route53.amazonaws.com" }
#              Resource = "*"
#              Sid = "Allow Route 53 DNSSEC Service"
#            },
#            {
#              Action = "kms:*"
#              Effect = "Allow"
#              Principal = { AWS = "arn:aws:iam::ACCOUNT_ID:root" }
#              Resource = "*"
#              Sid = "Enable IAM User Permissions"
#            }
#          ]
#          Version = "2012-10-17"
#        })
#      }
#      resource "aws_route53_key_signing_key" "dnssec" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "${var.domain_name}-ksk"
#      }
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#        depends_on     = [aws_route53_key_signing_key.dnssec]
#      }
#   7. WARNING: Disabling DNSSEC improperly can cause domain unavailability - follow AWS documentation
# TODO: CKV2_AWS_39 - DNS query logging not enabled for Route 53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch resources in us-east-1 region with specific IAM policies and has cost implications
# Fix: To enable DNS query logging for this hosted zone:
#   1. Create CloudWatch log group in us-east-1 region with appropriate retention
#   2. Create CloudWatch log resource policy to allow Route 53 to write logs
#   3. Create aws_route53_query_log resource linking the hosted zone to the log group
#   4. Consider log retention period based on compliance/audit requirements
#   5. Be aware of CloudWatch Logs costs for storage and ingestion
#   6. Example implementation:
#      # Ensure this uses us-east-1 region
#      resource "aws_cloudwatch_log_group" "route53_query_logs" {
#        provider          = aws.us-east-1  # Must be us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30  # Adjust based on requirements
#      }
#      data "aws_iam_policy_document" "route53_query_log_policy" {
#        statement {
#          actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
#          resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#          principals {
#            identifiers = ["route53.amazonaws.com"]
#            type        = "Service"
#          }
#        }
#      }
#      resource "aws_cloudwatch_log_resource_policy" "route53_query_log_policy" {
#        provider        = aws.us-east-1  # Must be us-east-1
#        policy_document = data.aws_iam_policy_document.route53_query_log_policy.json
#        policy_name     = "route53-query-logging-policy"
#      }
#      resource "aws_route53_query_log" "query_log" {
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_log_policy]
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
