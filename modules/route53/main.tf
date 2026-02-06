# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Enable DNSSEC signing for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC setup requires multi-regional resources and organizational policy decisions
# Fix: Steps to remediate:
#   1. Configure AWS provider alias for us-east-1 region (KMS key must be in us-east-1)
#   2. Create KMS key with ECC_NIST_P256 spec and SIGN_VERIFY usage in us-east-1:
#      resource "aws_kms_key" "dnssec" {
#        provider                 = aws.us-east-1
#        customer_master_key_spec = "ECC_NIST_P256"
#        deletion_window_in_days  = 7
#        key_usage                = "SIGN_VERIFY"
#        policy                   = <policy allowing dnssec-route53.amazonaws.com>
#      }
#   3. Create Route53 key signing key:
#      resource "aws_route53_key_signing_key" "example" {
#        hosted_zone_id             = aws_route53_zone.hosted_zone.id
#        key_management_service_arn = aws_kms_key.dnssec.arn
#        name                       = "dnssec-ksk"
#      }
#   4. Enable DNSSEC for hosted zone:
#      resource "aws_route53_hosted_zone_dnssec" "example" {
#        depends_on     = [aws_route53_key_signing_key.example]
#        hosted_zone_id = aws_route53_zone.hosted_zone.id
#      }
#   5. Add DS records to parent zone (if subdomain) or domain registrar
#   6. Test DNS resolution and DNSSEC validation before production use
# TODO: CKV2_AWS_39 - Enable DNS query logging for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch resources in us-east-1 and resource policy configuration
# Fix: Steps to remediate:
#   1. Configure AWS provider alias for us-east-1 region (CloudWatch log group must be in us-east-1)
#   2. Create CloudWatch log group in us-east-1:
#      resource "aws_cloudwatch_log_group" "route53_query_log" {
#        provider          = aws.us-east-1
#        name              = "/aws/route53/${var.domain_name}"
#        retention_in_days = 30  # Adjust based on compliance requirements
#      }
#   3. Create CloudWatch log resource policy to allow Route53 to write logs:
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
#   4. Create Route53 query log configuration:
#      resource "aws_route53_query_log" "example" {
#        depends_on               = [aws_cloudwatch_log_resource_policy.route53_query_logging]
#        cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log.arn
#        zone_id                  = aws_route53_zone.hosted_zone.zone_id
#      }
#   5. Review log retention and CloudWatch costs with finance/compliance teams
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
