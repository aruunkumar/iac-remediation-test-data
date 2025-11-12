output "hosted_zone_id" {
  description = "The ID of the hosted zone"
  value       = aws_route53_zone.hosted_zone.zone_id
}

output "supernova_role_arn" {
  description = "The ARN of the SuperNova role"
  value       = aws_iam_role.supernova_role.arn
}