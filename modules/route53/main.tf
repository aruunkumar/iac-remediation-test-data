# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Enable DNSSEC signing for Route53 public hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC requires multi-step process with domain registrar coordination and KMS key creation. Risk of DNS resolution issues if misconfigured.
# Fix: Enable DNSSEC signing following these steps:
#
# 1. Create KMS key for DNSSEC signing (must be in us-east-1 region):
#    resource "aws_kms_key" "dnssec" {
#      provider                 = aws.us-east-1
#      customer_master_key_spec = "ECC_NIST_P256"
#      deletion_window_in_days  = 7
#      key_usage                = "SIGN_VERIFY"
#      policy = jsonencode({
#        Statement = [
#          {
#            Action = [
#              "kms:DescribeKey",
#              "kms:GetPublicKey",
#              "kms:Sign",
#            ],
#            Effect = "Allow"
#            Principal = {
#              Service = "dnssec-route53.amazonaws.com"
#            }
#            Sid      = "Allow Route 53 DNSSEC Service"
#            Resource = "*"
#          },
#          {
#            Action = "kms:*"
#            Effect = "Allow"
#            Principal = {
#              AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#            }
#            Resource = "*"
#            Sid      = "Enable IAM User Permissions"
#          },
#        ]
#        Version = "2012-10-17"
#      })
#    }
#
# 2. Enable DNSSEC signing:
#    resource "aws_route53_key_signing_key" "dnssec_ksk" {
#      hosted_zone_id             = aws_route53_zone.hosted_zone.id
#      key_management_service_arn = aws_kms_key.dnssec.arn
#      name                       = "dnssec-ksk"
#    }
#
#    resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#      hosted_zone_id = aws_route53_key_signing_key.dnssec_ksk.hosted_zone_id
#    }
#
# 3. Get DS record from Route53:
#    After enabling, retrieve DS records and add them to your domain registrar:
#    - Sign in to Route53 console
#    - Select the hosted zone
#    - Copy the DS record
#    - Add DS record to your domain registrar's configuration
#
# WARNING: Do not enable DNSSEC until DS records are properly configured at registrar to avoid DNS resolution failures.

# TODO: CKV2_AWS_39 - Enable DNS query logging for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires CloudWatch Log Group creation and decisions on log retention (cost implications). Multi-resource coordination needed.
# Fix: Create CloudWatch Log Group and enable query logging:
#
# 1. Create CloudWatch Log Group for DNS query logs:
#    resource "aws_cloudwatch_log_group" "route53_query_log" {
#      name              = "/aws/route53/${var.domain_name}"
#      retention_in_days = 7  # Adjust based on compliance/cost requirements (1, 3, 5, 7, 14, 30, 60, 90, etc.)
#
#      tags = {
#        Name = "route53-query-logs"
#      }
#    }
#
# 2. Create CloudWatch Log Resource Policy (required for Route53 to write logs):
#    data "aws_iam_policy_document" "route53_query_logging_policy" {
#      statement {
#        actions = [
#          "logs:CreateLogStream",
#          "logs:PutLogEvents",
#        ]
#
#        resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#
#        principals {
#          identifiers = ["route53.amazonaws.com"]
#          type        = "Service"
#        }
#      }
#    }
#
#    resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
#      policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#      policy_name     = "route53-query-logging-policy"
#    }
#
# 3. Enable query logging for the hosted zone:
#    resource "aws_route53_query_log" "query_log" {
#      depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
#
#      cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
#      zone_id                  = aws_route53_zone.hosted_zone.zone_id
#    }

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
