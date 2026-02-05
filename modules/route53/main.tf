# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - DNSSEC signing not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires manual intervention - DNSSEC requires KMS key, coordination with domain registrar, and careful implementation
# Fix: To enable DNSSEC signing for this hosted zone:
#   1. Create a KMS key in us-east-1 region with customer_master_key_spec = "ECC_NIST_P256" and key_usage = "SIGN_VERIFY"
#   2. Configure KMS key policy to allow Route 53 DNSSEC Service to use the key (DescribeKey, GetPublicKey, Sign actions)
#   3. Create an aws_route53_key_signing_key resource referencing the hosted zone and KMS key
#   4. Create an aws_route53_hosted_zone_dnssec resource with signing_status = "SIGNING"
#   5. Update DS records at your domain registrar with the values from the key signing key
#   6. WARNING: Disabling DNSSEC incorrectly can cause domain unavailability - follow AWS documentation carefully
# TODO: CKV2_AWS_39 - DNS query logging not enabled for Route53 hosted zone
# Resource: aws_route53_zone.hosted_zone
# Reason: Requires manual intervention - Query logging requires CloudWatch resources in us-east-1 and has cost implications
# Fix: To enable DNS query logging for this hosted zone:
#   1. Create an aws_cloudwatch_log_group in us-east-1 region with name "/aws/route53/${var.domain_name}"
#   2. Set appropriate retention_in_days for the log group (e.g., 30, 90, or as per compliance requirements)
#   3. Create an aws_cloudwatch_log_resource_policy to allow Route53 to write logs (CreateLogStream, PutLogEvents actions)
#   4. Create an aws_route53_query_log resource linking the hosted zone to the CloudWatch log group
#   5. Consider cost implications of log storage and retention period
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