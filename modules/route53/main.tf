# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Ensure Domain Name System Security Extensions (DNSSEC) signing is enabled for Amazon Route 53 public hosted zones
# Resource: aws_route53_zone.hosted_zone
# Reason: Enabling DNSSEC requires multiple complex resources and careful coordination:
#   - KMS key must be created in us-east-1 region with specific configuration (ECC_NIST_P256)
#   - KMS key policy must grant permissions to dnssec-route53.amazonaws.com
#   - Key Signing Key (KSK) must be created and activated
#   - DNSSEC signing must be enabled on the hosted zone
#   - DS records must be added to parent zone (domain registrar)
#   - Risk of domain unavailability if not done correctly
#   - Requires careful testing and validation
# Fix: To enable DNSSEC signing for Route 53 hosted zone:
#   1. Create a KMS key in us-east-1 region with proper configuration:
#      resource "aws_kms_key" "dnssec" {
#        provider                 = aws.us-east-1  # Must be us-east-1
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
#              Condition = {
#                StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
#                ArnLike = { "aws:SourceArn" = "arn:aws:route53:::hostedzone/*" }
#              }
#            },
#            {
#              Action = "kms:CreateGrant"
#              Effect = "Allow"
#              Principal = { Service = "dnssec-route53.amazonaws.com" }
#              Resource = "*"
#              Sid = "Allow Route 53 DNSSEC Service to CreateGrant"
#              Condition = { Bool = { "kms:GrantIsForAWSResource" = "true" } }
#            },
#            {
#              Action = "kms:*"
#              Effect = "Allow"
#              Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
#              Resource = "*"
#              Sid = "Enable IAM User Permissions"
#            }
#          ]
#          Version = "2012-10-17"
#        })
#      }
#   2. Create a Key Signing Key (KSK):
#      resource "aws_route53_key_signing_key" "dnssec" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "${var.domain_name}-ksk"
#      }
#   3. Enable DNSSEC signing on the hosted zone:
#      resource "aws_route53_hosted_zone_dnssec" "dnssec" {
#        depends_on     = [aws_route53_key_signing_key.dnssec]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }
#   4. After Terraform apply, retrieve DS records from the hosted zone
#   5. Add DS records to your domain registrar's DNS configuration
#   6. Wait for DNS propagation before considering DNSSEC fully active
#   7. Monitor DNSSEC validation using tools like dnsviz.net
# Note: Disabling DNSSEC requires careful planning to avoid domain unavailability

# TODO: CKV2_AWS_39 - Ensure Domain Name System (DNS) query logging is enabled for Amazon Route 53 hosted zones
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires multiple resources and specific regional configuration:
#   - CloudWatch log group must be in us-east-1 region (Route53 requirement)
#   - CloudWatch log resource policy must allow Route53 service to write logs
#   - Only works with public hosted zones (not private zones)
#   - Cost implications for CloudWatch Logs storage and analysis
#   - Requires decision on log retention period
# Fix: To enable DNS query logging for Route 53 hosted zone:
#   1. Create a CloudWatch log group in us-east-1:
#      provider "aws" {
#        alias  = "us-east-1"
#        region = "us-east-1"
#      }
#      resource "aws_cloudwatch_log_group" "route53_query_log" {
#        provider          = aws.us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30  # Adjust based on requirements
#      }
#   2. Create CloudWatch log resource policy to allow Route53 to write logs:
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
#        provider        = aws.us-east-1
#        policy_document = data.aws_iam_policy_document.route53_query_logging_policy.json
#        policy_name     = "route53-query-logging-policy"
#      }
#   3. Enable query logging for the hosted zone:
#      resource "aws_route53_query_log" "hosted_zone_query_log" {
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging_policy]
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#      }
#   4. Verify logs are being written to CloudWatch Logs
#   5. Set up CloudWatch Insights queries or alarms as needed for monitoring
# Note: Query logging is only available for public hosted zones

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
