# Route53 module - Creates a Route 53 hosted zone and IAM role

# AGENT-FIXED: CKV2_AWS_38 - Created KMS key, key signing key, and enabled DNSSEC signing for Route53 hosted zone
# Note: After enabling DNSSEC, you must manually update DS records at your domain registrar
# Configure AWS provider for us-east-1 (required for Route53 DNSSEC and query logging)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# Create KMS key for DNSSEC signing (must be in us-east-1)
resource "aws_kms_key" "dnssec" {
  provider                 = aws.us-east-1
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  description              = "KMS key for Route53 DNSSEC signing - ${var.domain_name}"

  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify",
        ]
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Allow Route 53 DNSSEC Service"
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name

  # Apply a lifecycle policy to retain the hosted zone on destroy
  lifecycle {
    prevent_destroy = true
  }
}

# AGENT-FIXED: CKV2_AWS_38 - Created key signing key for DNSSEC
resource "aws_route53_key_signing_key" "dnssec_ksk" {
  hosted_zone_id             = aws_route53_zone.hosted_zone.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = replace(var.domain_name, ".", "-")
}

# AGENT-FIXED: CKV2_AWS_38 - Enabled DNSSEC signing for hosted zone
resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  hosted_zone_id = aws_route53_key_signing_key.dnssec_ksk.hosted_zone_id
  signing_status = "SIGNING"

  depends_on = [
    aws_route53_key_signing_key.dnssec_ksk
  ]
}

# TODO: CKV2_AWS_38 - Manual step required after Terraform apply
# After enabling DNSSEC, you MUST update DS records at your domain registrar:
#   1. Retrieve DS record values: aws route53 get-dnssec <hosted-zone-id>
#   2. Add these DS records to your domain registrar's DNS configuration
#   3. Wait for DNS propagation (can take up to 48 hours)
# WARNING: Do not disable DNSSEC before DNS propagation is complete or domain may become unavailable

# AGENT-FIXED: CKV2_AWS_39 - Created CloudWatch Log Group for Route53 query logging (must be in us-east-1)
resource "aws_cloudwatch_log_group" "route53_query_logs" {
  provider          = aws.us-east-1
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days
}

# AGENT-FIXED: CKV2_AWS_39 - Created CloudWatch log resource policy to allow Route53 to write logs
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

resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
  provider        = aws.us-east-1
  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
  policy_name     = "route53-query-logging-policy"
}

# AGENT-FIXED: CKV2_AWS_39 - Enabled DNS query logging for hosted zone
resource "aws_route53_query_log" "query_log" {
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
  zone_id                  = aws_route53_zone.hosted_zone.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
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
