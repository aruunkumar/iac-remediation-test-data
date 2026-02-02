# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing is not enabled for Route 53 public hosted zone
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: DNSSEC implementation requires complex multi-step setup with specific KMS configuration and potential DNS propagation risks
# Fix: To enable DNSSEC signing for the hosted zone:
#   1. Create a KMS key in us-east-1 region with the following specifications:
#      - customer_master_key_spec = "ECC_NIST_P256"
#      - key_usage = "SIGN_VERIFY"
#      - Configure policy to allow dnssec-route53.amazonaws.com service access
#   2. Create an aws_route53_key_signing_key resource:
#      - Reference the hosted zone ID
#      - Reference the KMS key ARN from step 1
#      - Provide a unique name for the KSK
#   3. Create an aws_route53_hosted_zone_dnssec resource:
#      - Reference the hosted zone ID
#      - Add dependency on the key signing key
#      - Set signing_status = "SIGNING" (default)
#   4. After Terraform apply, establish chain of trust with parent zone:
#      - Retrieve DS record from the key signing key output
#      - Add DS record to parent zone (domain registrar)
#   5. Monitor DNSSEC validation using dig +dnssec command
#   6. WARNING: Disabling DNSSEC later requires careful timing to avoid domain unavailability
# TODO: CKV2_AWS_39 - DNS query logging is not enabled for Route 53 hosted zone
# Resource: module.route53.aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch resources in us-east-1 region and additional cost considerations
# Fix: To enable DNS query logging for the hosted zone:
#   1. Create CloudWatch log group in us-east-1 region:
#      - Use provider alias for us-east-1 if main provider is different region
#      - Name format: "/aws/route53/${var.domain_name}"
#      - Set retention_in_days based on compliance requirements (e.g., 30, 90, 365)
#   2. Create CloudWatch log resource policy:
#      - Allow route53.amazonaws.com service to CreateLogStream and PutLogEvents
#      - Resource: "arn:aws:logs:*:*:log-group:/aws/route53/*"
#   3. Create aws_route53_query_log resource:
#      - Set cloudwatch_log_group_arn to the log group created in step 1
#      - Set zone_id to aws_route53_zone.hosted_zone.zone_id
#      - Add dependency on the CloudWatch log resource policy
#   4. Consider costs: Query logging charges apply per million queries logged
#   5. Set up CloudWatch alarms or insights for DNS query monitoring
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
