# Route53 module - Creates a Route 53 hosted zone and IAM role

# TODO: CKV2_AWS_38 - Brief description of the issue
# Resource: aws_route53_zone.hosted_zone
# Reason: DNSSEC signing requires complex setup with KMS key in us-east-1, coordination with domain registrar, and risk of domain unavailability if misconfigured
# Fix: Specific steps to remediate:
#   1. Create a KMS key in us-east-1 region with customer_master_key_spec = "ECC_NIST_P256" and key_usage = "SIGN_VERIFY"
#   2. Configure KMS key policy to allow dnssec-route53.amazonaws.com service access
#   3. Add resource: aws_route53_key_signing_key with hosted_zone_id and key_management_service_arn
#   4. Add resource: aws_route53_hosted_zone_dnssec with hosted_zone_id and depends_on the key_signing_key
#   5. After Terraform apply, retrieve the DS record from the key_signing_key output
#   6. Add the DS record to your domain registrar to complete DNSSEC chain of trust
#   7. Test DNSSEC validation before enabling in production
# TODO: CKV2_AWS_39 - Brief description of the issue
# Resource: aws_route53_zone.hosted_zone
# Reason: Query logging requires CloudWatch log group and resource policy in us-east-1, cross-region provider setup, and has cost implications for log storage
# Fix: Specific steps to remediate:
#   1. Configure an AWS provider alias for us-east-1 region if not already in that region
#   2. Create aws_cloudwatch_log_group in us-east-1 with name = "/aws/route53/${var.domain_name}"
#   3. Set appropriate retention_in_days based on compliance requirements (e.g., 30, 90, 365)
#   4. Create aws_iam_policy_document for Route53 query logging with actions: logs:CreateLogStream, logs:PutLogEvents
#   5. Create aws_cloudwatch_log_resource_policy in us-east-1 with the policy document
#   6. Add resource: aws_route53_query_log with cloudwatch_log_group_arn and zone_id
#   7. Ensure depends_on relationship to cloudwatch_log_resource_policy
#   8. Review and approve costs for CloudWatch Logs storage
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
