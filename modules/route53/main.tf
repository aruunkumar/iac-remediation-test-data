# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Ensure DNSSEC signing is enabled for Route 53 public hosted zones
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: Requires specialized KMS key configuration, multi-resource coordination, and critical out-of-band registrar actions with high risk of DNS disruption
# Fix: 1. Create KMS key for DNSSEC signing (MUST use ECC_NIST_P256 spec):
#      resource "aws_kms_key" "dnssec" {
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = jsonencode({
#          Statement = [{
#            Action   = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign"]
#            Effect   = "Allow"
#            Principal = { Service = "dnssec-route53.amazonaws.com" }
#            Resource = "*"
#            Sid      = "Allow Route 53 DNSSEC Service"
#          }, {
#            Action   = "kms:*"
#            Effect   = "Allow"
#            Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
#            Resource = "*"
#            Sid      = "Enable IAM User Permissions"
#          }]
#          Version = "2012-10-17"
#        })
#      }
#      2. Create Key Signing Key:
#      resource "aws_route53_key_signing_key" "ksk" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "ksk-${var.domain_name}"
#      }
#      3. Enable DNSSEC signing:
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        hosted_zone_id = aws_route53_key_signing_key.ksk.hosted_zone_id
#      }
#      4. CRITICAL: Add DS records to parent zone at domain registrar to establish chain of trust
#         Failure to complete this step will break DNS resolution!

# TODO: CKV2_AWS_39 - Ensure DNS query logging is enabled for Route 53 hosted zones
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: Requires CloudWatch log group creation, resource policy for Route53 write permissions, and business decision on log retention with cost implications
# Fix: 1. Create CloudWatch log group:
#      resource "aws_cloudwatch_log_group" "route53_query_logs" {
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 7  # Adjust based on compliance/cost requirements
#      }
#      2. Create resource policy to allow Route53 to write logs:
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
#        policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#        policy_name     = "route53-query-logging-policy"
#      }
#      3. Enable query logging:
#      resource "aws_route53_query_log" "query_log" {
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
