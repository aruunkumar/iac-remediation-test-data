# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Ensure DNSSEC signing is enabled for Route 53 public hosted zones
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC implementation requires careful planning and manual steps to avoid domain unavailability
# Fix: To remediate this finding:
#   1. Create a KMS key in us-east-1 region with customer_master_key_spec = "ECC_NIST_P256"
#   2. Configure KMS key policy to allow Route 53 DNSSEC service access
#   3. Create aws_route53_key_signing_key resource linking the hosted zone to the KMS key
#   4. Create aws_route53_hosted_zone_dnssec resource to enable DNSSEC signing
#   5. Add DS records to your domain registrar (critical step - domain unavailability risk if not done)
#   6. Monitor the signing status before going live
#   WARNING: Disabling DNSSEC incorrectly can make your domain unavailable on the internet
#   Example resources needed:
#     resource "aws_kms_key" "dnssec" {
#       provider                 = aws.us-east-1
#       customer_master_key_spec = "ECC_NIST_P256"
#       deletion_window_in_days  = 7
#       key_usage                = "SIGN_VERIFY"
#       policy                   = <see AWS docs for required policy>
#     }
#     resource "aws_route53_key_signing_key" "ksk" {
#       hosted_zone_id             = aws_route53_zone.hosted_zone.id
#       key_management_service_arn = aws_kms_key.dnssec.arn
#       name                       = "${var.domain_name}-ksk"
#     }
#     resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#       depends_on     = [aws_route53_key_signing_key.ksk]
#       hosted_zone_id = aws_route53_zone.hosted_zone.id
#     }
resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name

  # Apply a lifecycle policy to retain the hosted zone on destroy
  lifecycle {
    prevent_destroy = true
  }
}

# AGENT-FIXED: CKV2_AWS_39 - Enabled DNS query logging for Route 53 hosted zone
# AGENT-FIXED: CKV_AWS_338 - Set retention to at least 365 days (1 year) for compliance
# AGENT-FIXED: CKV_AWS_158 - Added KMS encryption for CloudWatch log group
# CloudWatch log group for Route 53 query logging (must be in us-east-1)
resource "aws_cloudwatch_log_group" "route53_query_log" {
  provider          = aws.us-east-1
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days != null && var.query_log_retention_days >= 365 ? var.query_log_retention_days : 365
  kms_key_id        = var.cloudwatch_kms_key_arn

  tags = {
    Name        = "route53-query-logs-${var.domain_name}"
    Environment = var.environment
  }
}

# AGENT-FIXED: CKV2_AWS_39 - CloudWatch log resource policy to allow Route 53 to write logs
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
  provider = aws.us-east-1

  policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
  policy_name     = "route53-query-logging-policy-${var.domain_name}"
}

# AGENT-FIXED: CKV2_AWS_39 - Route 53 query logging configuration
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
