output "hosted_zone_id" {
  description = "The ID of the hosted zone"
  value       = aws_route53_zone.hosted_zone.zone_id
}

output "supernova_role_arn" {
  description = "The ARN of the SuperNova role"
  value       = aws_iam_role.supernova_role.arn
}

# AGENT-FIXED: CKV2_AWS_39 - Added outputs for Route53 query logging resources
output "query_log_id" {
  description = "The ID of the Route53 query logging configuration"
  value       = aws_route53_query_log.query_log.id
}

output "query_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for Route53 query logs"
  value       = aws_cloudwatch_log_group.route53_query_log.arn
}
