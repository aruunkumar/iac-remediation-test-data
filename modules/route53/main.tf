# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Route53 hosted zone requires DNSSEC signing to be enabled
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires creating a KMS key in us-east-1 with specific configuration and updating domain registrar with DS records
# Fix: To enable DNSSEC signing for the hosted zone:
#   1. Create a KMS key in us-east-1 region with the following configuration:
#      resource "aws_kms_key" "dnssec_key" {
#        provider                 = aws.us-east-1
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
#              Sid      = "Allow Route 53 DNSSEC Service"
#            },
#            {
#              Action = "kms:CreateGrant"
#              Effect = "Allow"
#              Principal = { Service = "dnssec-route53.amazonaws.com" }
#              Resource = "*"
#              Sid      = "Allow Route 53 DNSSEC Service to CreateGrant"
#              Condition = { Bool = { "kms:GrantIsForAWSResource" = "true" } }
#            },
#            {
#              Action = "kms:*"
#              Effect = "Allow"
#              Principal = { AWS = "arn:aws:iam::ACCOUNT_ID:root" }
#              Resource = "*"
#              Sid      = "Enable IAM User Permissions"
#            }
#          ]
#          Version = "2012-10-17"
#        })
#      }
#   2. Create a key signing key (KSK):
#      resource "aws_route53_key_signing_key" "dnssec_ksk" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec_key.arn
#        name                       = "${var.domain_name}-ksk"
#      }
#   3. Enable DNSSEC signing:
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        depends_on     = [aws_route53_key_signing_key.dnssec_ksk]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }
#   4. After applying, retrieve the DS record from the KSK and add it to your domain registrar
#   5. Verify DNSSEC is working using tools like dnsviz.net or dig +dnssec
# TODO: CKV2_AWS_39 - Route53 hosted zone requires DNS query logging to be enabled
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires creating a CloudWatch log group in us-east-1 and a CloudWatch log resource policy to allow Route53 to write logs
# Fix: To enable DNS query logging:
#   1. Create a CloudWatch log group in us-east-1 region:
#      resource "aws_cloudwatch_log_group" "route53_query_logs" {
#        provider          = aws.us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30
#        kms_key_id        = aws_kms_key.logs_key.arn  # Optional: for encryption
#      }
#   2. Create an IAM policy document for Route53 to write logs:
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
#   3. Create a CloudWatch log resource policy:
#      resource "aws_cloudwatch_log_resource_policy" "route53_query_logging_policy" {
#        provider        = aws.us-east-1
#        policy_name     = "route53-query-logging-policy"
#        policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#      }
#   4. Enable query logging for the hosted zone:
#      resource "aws_route53_query_log" "query_log" {
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#      }
#   5. Note: Query logging is only available for public hosted zones
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
