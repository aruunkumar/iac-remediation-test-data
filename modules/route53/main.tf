# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Route53 hosted zone requires DNSSEC signing to be enabled
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC requires creating a KMS key in us-east-1, a key signing key, and DNSSEC resource with complex dependencies and region-specific requirements, plus manual DS record updates at domain registrar
# Fix: To remediate this issue:
#   1. Ensure provider configuration for us-east-1 region exists (required by Route53 DNSSEC)
#   2. Create a KMS key in us-east-1 region with ECC_NIST_P256 spec:
#      resource "aws_kms_key" "dnssec" {
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = jsonencode({
#          Statement = [
#            {
#              Action = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign", "kms:Verify"]
#              Effect = "Allow"
#              Principal = { Service = "dnssec-route53.amazonaws.com" }
#              Resource = "*"
#              Sid = "Allow Route 53 DNSSEC Service"
#            },
#            {
#              Action = "kms:*"
#              Effect = "Allow"
#              Principal = { AWS = data.aws_caller_identity.current.arn }
#              Resource = "*"
#              Sid = "Enable IAM User Permissions"
#            }
#          ]
#          Version = "2012-10-17"
#        })
#      }
#   3. Create a key signing key:
#      resource "aws_route53_key_signing_key" "dnssec" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "dnssec-ksk"
#      }
#   4. Enable DNSSEC signing:
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        depends_on     = [aws_route53_key_signing_key.dnssec]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }
#   5. After Terraform apply, retrieve DS records from Route53 console
#   6. Add DS records to parent zone at domain registrar
#   7. Wait for DNS propagation before enabling DNSSEC (critical to prevent domain unavailability)

# AGENT-FIXED: CKV2_AWS_39 - Added Route53 query logging with CloudWatch Logs
# Note: Route53 query logging requires resources to be in us-east-1 region per AWS requirements
data "aws_caller_identity" "current" {}

# AGENT-FIXED: CKV_AWS_338 - Set retention_in_days to 365 days (1 year minimum)
# TODO: CKV_AWS_158 - CloudWatch log group requires KMS encryption
# Resource: aws_cloudwatch_log_group.route53_query_log
# Reason: KMS encryption requires a KMS key to be provisioned and proper key policies configured, which are organization-specific decisions
# Fix: To remediate this issue:
#   1. Create or reference a KMS key for CloudWatch Logs encryption:
#      resource "aws_kms_key" "cloudwatch_logs" {
#        description             = "KMS key for CloudWatch Logs encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#        policy = jsonencode({
#          Version = "2012-10-17"
#          Statement = [
#            {
#              Sid    = "Enable IAM User Permissions"
#              Effect = "Allow"
#              Principal = {
#                AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#              }
#              Action   = "kms:*"
#              Resource = "*"
#            },
#            {
#              Sid    = "Allow CloudWatch Logs"
#              Effect = "Allow"
#              Principal = {
#                Service = "logs.amazonaws.com"
#              }
#              Action = [
#                "kms:Encrypt",
#                "kms:Decrypt",
#                "kms:ReEncrypt*",
#                "kms:GenerateDataKey*",
#                "kms:CreateGrant",
#                "kms:DescribeKey"
#              ]
#              Resource = "*"
#              Condition = {
#                ArnLike = {
#                  "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/route53/*"
#                }
#              }
#            }
#          ]
#        })
#      }
#   2. Add kms_key_id to this log group:
#      kms_key_id = aws_kms_key.cloudwatch_logs.arn
#   3. Ensure the KMS key is in the same region as the log group
resource "aws_cloudwatch_log_group" "route53_query_log" {
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = 365

  tags = {
    Name        = "route53-query-logs-${var.domain_name}"
    Description = "DNS query logs for ${var.domain_name}"
  }
}

data "aws_iam_policy_document" "route53_query_log_policy" {
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

resource "aws_cloudwatch_log_resource_policy" "route53_query_log_policy" {
  policy_document = data.aws_iam_policy_document.route53_query_log_policy.json
  policy_name     = "route53-query-logging-policy-${replace(var.domain_name, ".", "-")}"
}

resource "aws_route53_query_log" "query_log" {
  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_log_policy]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
  zone_id                  = aws_route53_zone.hosted_zone.zone_id
}

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
