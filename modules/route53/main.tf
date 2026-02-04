# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC signing requires creating a KMS key with specific configuration, Key Signing Key setup, and coordination with domain registrar to add DS records
# Fix: To enable DNSSEC signing, complete the following steps:
#   1. Create a KMS key in us-east-1 region with:
#      - customer_master_key_spec = "ECC_NIST_P256"
#      - key_usage = "SIGN_VERIFY"
#      - Policy allowing dnssec-route53.amazonaws.com service access
#   2. Create aws_route53_key_signing_key resource with:
#      - hosted_zone_id = aws_route53_zone.hosted_zone.id
#      - key_management_service_arn = aws_kms_key.<key>.arn
#      - name = "<unique_ksk_name>"
#   3. Create aws_route53_hosted_zone_dnssec resource with:
#      - hosted_zone_id = aws_route53_key_signing_key.<ksk>.hosted_zone_id
#      - depends_on = [aws_route53_key_signing_key.<ksk>]
#   4. After enabling DNSSEC, add the DS records to your domain registrar
#   5. Monitor DNSSEC status before making changes to avoid domain unavailability
# TODO: CKV2_AWS_39 - DNS query logging is not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch Log Group in us-east-1, CloudWatch Log Resource Policy, and organizational decisions on log retention
# Fix: To enable DNS query logging, complete the following steps:
#   1. Create a CloudWatch Log Group in us-east-1 region:
#      - name = "/aws/route53/${var.domain_name}"
#      - retention_in_days = <your_retention_policy> (e.g., 30, 90, 365)
#   2. Create aws_cloudwatch_log_resource_policy in us-east-1 with:
#      - policy_name = "route53-query-logging-policy"
#      - Allow route53.amazonaws.com to CreateLogStream and PutLogEvents
#      - Resource: "arn:aws:logs:*:*:log-group:/aws/route53/*"
#   3. Create aws_route53_query_log resource with:
#      - cloudwatch_log_group_arn = aws_cloudwatch_log_group.<log_group>.arn
#      - zone_id = aws_route53_zone.hosted_zone.zone_id
#      - depends_on = [aws_cloudwatch_log_resource_policy.<policy>]
#   4. Note: This will incur additional costs for CloudWatch Logs storage
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
