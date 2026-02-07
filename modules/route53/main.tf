# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC requires multiple resources and complex configuration:
#         1. KMS key must be in us-east-1 region with specific DNSSEC policy
#         2. Requires aws_route53_key_signing_key and aws_route53_hosted_zone_dnssec resources
#         3. DNSSEC configuration is domain-specific and has propagation considerations
#         4. Disabling DNSSEC after enabling requires careful DNS propagation management
# Fix: To enable DNSSEC signing:
#   1. Create a KMS key in us-east-1 region with customer_master_key_spec = "ECC_NIST_P256" and key_usage = "SIGN_VERIFY"
#   2. Add KMS key policy to allow dnssec-route53.amazonaws.com service access
#   3. Create aws_route53_key_signing_key resource linking the hosted zone to the KMS key
#   4. Create aws_route53_hosted_zone_dnssec resource to enable DNSSEC signing
#   5. Add DS records to parent zone's DNS configuration
#   6. Example:
#      resource "aws_kms_key" "dnssec" {
#        provider                 = aws.us-east-1
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy = jsonencode({
#          Statement = [{
#            Action = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign", "kms:Verify"]
#            Effect = "Allow"
#            Principal = { Service = "dnssec-route53.amazonaws.com" }
#            Resource = "*"
#          }]
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
# TODO: CKV2_AWS_39 - DNS query logging is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch resources in us-east-1 region and IAM policies:
#         1. CloudWatch log group must be created in us-east-1 region
#         2. CloudWatch log resource policy must allow Route53 service access
#         3. Only works for public hosted zones
#         4. Requires organization-specific decisions on log retention and management
# Fix: To enable DNS query logging:
#   1. Create CloudWatch log group in us-east-1 with naming pattern /aws/route53/{domain_name}
#   2. Create CloudWatch log resource policy allowing route53.amazonaws.com to write logs
#   3. Create aws_route53_query_log resource linking the hosted zone to the log group
#   4. Example:
#      resource "aws_cloudwatch_log_group" "route53_query_logs" {
#        provider          = aws.us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30
#      }
#      data "aws_iam_policy_document" "route53_query_logging" {
#        statement {
#          actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
#          resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
#          principals {
#            identifiers = ["route53.amazonaws.com"]
#            type        = "Service"
#          }
#        }
#      }
#      resource "aws_cloudwatch_log_resource_policy" "route53_query_logging" {
#        provider        = aws.us-east-1
#        policy_document = data.aws_iam_policy_document.route53_query_logging.json
#        policy_name     = "route53-query-logging-policy"
#      }
#      resource "aws_route53_query_log" "query_log" {
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging]
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
