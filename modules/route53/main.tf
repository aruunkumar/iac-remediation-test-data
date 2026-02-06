# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Enabling DNSSEC requires creating a KMS key in us-east-1, configuring Key Signing Key (KSK), and updating domain registrar with DS records, which involves external dependencies and complex multi-step configuration
# Fix: Enable DNSSEC signing for the hosted zone:
#   1. Create a KMS key in us-east-1 region with specific DNSSEC requirements:
#      provider "aws" {
#        alias  = "us-east-1"
#        region = "us-east-1"
#      }
#      data "aws_caller_identity" "current" {}
#      resource "aws_kms_key" "dnssec" {
#        provider                 = aws.us-east-1
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = jsonencode({
#          Statement = [
#            {
#              Action = [
#                "kms:DescribeKey",
#                "kms:GetPublicKey",
#                "kms:Sign",
#                "kms:Verify",
#              ]
#              Effect = "Allow"
#              Principal = {
#                Service = "dnssec-route53.amazonaws.com"
#              }
#              Resource = "*"
#              Sid      = "Allow Route 53 DNSSEC Service"
#            },
#            {
#              Action = "kms:*"
#              Effect = "Allow"
#              Principal = {
#                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#              }
#              Resource = "*"
#              Sid      = "Enable IAM User Permissions"
#            },
#          ]
#          Version = "2012-10-17"
#        })
#      }
#   2. Create a Key Signing Key (KSK):
#      resource "aws_route53_key_signing_key" "dnssec_ksk" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "dnssec-ksk"
#      }
#   3. Enable DNSSEC for the hosted zone:
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        depends_on = [
#          aws_route53_key_signing_key.dnssec_ksk
#        ]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }
#   4. After applying, retrieve the DS record from the Key Signing Key output
#   5. Update your domain registrar with the DS record to complete DNSSEC chain of trust
#   6. WARNING: Do not disable DNSSEC without waiting for DNS propagation (TTL expiry) to avoid domain unavailability

# AGENT-FIXED: CKV2_AWS_39 - Created provider alias for us-east-1 region (required for Route53 query logging)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# AGENT-FIXED: CKV2_AWS_39 - Created CloudWatch Log Group for Route53 query logs in us-east-1
resource "aws_cloudwatch_log_group" "route53_query_log" {
  provider          = aws.us-east-1
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days

  tags = {
    Name = "route53-query-logs-${var.domain_name}"
  }
}

# AGENT-FIXED: CKV2_AWS_39 - Created IAM policy document for Route53 query logging permissions
data "aws_iam_policy_document" "route53_query_logging_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]

    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}

# AGENT-FIXED: CKV2_AWS_39 - Created CloudWatch log resource policy to allow Route53 to write query logs
resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  provider        = aws.us-east-1
  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
  policy_name     = "route53-query-logging-policy"
}

resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name

  # Apply a lifecycle policy to retain the hosted zone on destroy
  lifecycle {
    prevent_destroy = true
  }
}

# AGENT-FIXED: CKV2_AWS_39 - Enabled DNS query logging for the Route53 hosted zone
resource "aws_route53_query_log" "query_log" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
  zone_id                  = aws_route53_zone.hosted_zone.zone_id
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
