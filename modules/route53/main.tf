# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Enable DNSSEC signing for Route 53 public hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC requires complex setup with KMS key in us-east-1, key signing key, and DS record configuration at domain registrar
# Fix: To enable DNSSEC signing:
#   1. Create a KMS key in us-east-1 region with specific policy:
#     provider "aws" {
#       alias  = "us-east-1"
#       region = "us-east-1"
#     }
#     data "aws_caller_identity" "current" {}
#     resource "aws_kms_key" "dnssec" {
#       provider                 = aws.us-east-1
#       customer_master_key_spec = "ECC_NIST_P256"
#       deletion_window_in_days  = 7
#       key_usage                = "SIGN_VERIFY"
#       policy = jsonencode({
#         Statement = [
#           {
#             Action = [
#               "kms:DescribeKey",
#               "kms:GetPublicKey",
#               "kms:Sign",
#             ],
#             Effect = "Allow"
#             Principal = {
#               Service = "dnssec-route53.amazonaws.com"
#             }
#             Sid      = "Allow Route 53 DNSSEC Service"
#             Resource = "*"
#             Condition = {
#               StringEquals = {
#                 "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#               }
#               ArnLike = {
#                 "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
#               }
#             }
#           },
#           {
#             Action = "kms:CreateGrant"
#             Effect = "Allow"
#             Principal = {
#               Service = "dnssec-route53.amazonaws.com"
#             }
#             Sid      = "Allow Route 53 DNSSEC Service to CreateGrant"
#             Resource = "*"
#             Condition = {
#               Bool = {
#                 "kms:GrantIsForAWSResource" = "true"
#               }
#             }
#           },
#           {
#             Action = "kms:*"
#             Effect = "Allow"
#             Principal = {
#               AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#             }
#             Resource = "*"
#             Sid      = "Enable IAM User Permissions"
#           }
#         ]
#         Version = "2012-10-17"
#       })
#     }
#   2. Create a Route 53 Key Signing Key:
#     resource "aws_route53_key_signing_key" "dnssec_ksk" {
#       hosted_zone_id             = aws_route53_zone.hosted_zone.id
#       key_management_service_arn = aws_kms_key.dnssec.arn
#       name                       = "${var.domain_name}-ksk"
#     }
#   3. Enable DNSSEC for the hosted zone:
#     resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#       depends_on     = [aws_route53_key_signing_key.dnssec_ksk]
#       hosted_zone_id = aws_route53_zone.hosted_zone.id
#     }
#   4. Configure DS records at your domain registrar using the output from the key signing key
#   5. WARNING: Disabling DNSSEC requires careful planning to avoid DNS unavailability

# TODO: CKV2_AWS_39 - Enable DNS query logging for Route 53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch Log Group in us-east-1, log resource policy, and consideration of log retention/costs
# Fix: To enable DNS query logging:
#   1. Create a CloudWatch Log Group in us-east-1:
#     provider "aws" {
#       alias  = "us-east-1"
#       region = "us-east-1"
#     }
#     resource "aws_cloudwatch_log_group" "route53_query_logs" {
#       provider          = aws.us-east-1
#       name              = "/aws/route53/${var.domain_name}"
#       retention_in_days = 30  # Adjust based on compliance requirements
#     }
#   2. Create a CloudWatch Log Resource Policy to allow Route 53 to write logs:
#     data "aws_iam_policy_document" "route53_query_logging_policy" {
#       statement {
#         actions = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#         ]
#         resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#         principals {
#           identifiers = ["route53.amazonaws.com"]
#           type        = "Service"
#         }
#       }
#     }
#     resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
#       provider        = aws.us-east-1
#       policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#       policy_name     = "route53-query-logging-policy"
#     }
#   3. Enable query logging for the hosted zone:
#     resource "aws_route53_query_log" "hosted_zone_query_log" {
#       depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
#       cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
#       zone_id                  = aws_route53_zone.hosted_zone.zone_id
#     }
#   4. Consider log retention periods based on compliance requirements
#   5. Be aware of CloudWatch Logs pricing for storage and ingestion

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