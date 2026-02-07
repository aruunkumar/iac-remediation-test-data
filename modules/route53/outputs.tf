output "hosted_zone_id" {
  description = "The ID of the hosted zone"
  value       = aws_route53_zone.hosted_zone.zone_id
}

output "supernova_role_arn" {
  description = "The ARN of the SuperNova role"
  value       = aws_iam_role.supernova_role.arn
}

# AGENT-FIXED: CKV2_AWS_38 - Added outputs for DNSSEC resources
output "dnssec_kms_key_id" {
  description = "The ID of the KMS key used for DNSSEC signing"
  value       = aws_kms_key.dnssec.key_id
}

output "dnssec_key_signing_key_name" {
  description = "The name of the Route53 key signing key for DNSSEC"
  value       = aws_route53_key_signing_key.dnssec_ksk.name
}

output "dnssec_status" {
  description = "The DNSSEC signing status of the hosted zone"
  value       = aws_route53_hosted_zone_dnssec.dnssec.signing_status
}

# AGENT-FIXED: CKV2_AWS_39 - Added output for query logging
output "query_log_group_name" {
  description = "The name of the CloudWatch Log Group for Route53 query logs"
  value       = aws_cloudwatch_log_group.route53_query_logs.name
}

output "query_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for Route53 query logs"
  value       = aws_cloudwatch_log_group.route53_query_logs.arn
}
