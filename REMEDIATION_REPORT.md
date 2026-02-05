# Remediation Report

**Scan ID:** 227677f2-3279-4d35-89d1-4d3a5fb6cf12  
**Started:** 2026-02-05 17:21:05  
**Findings:** 10  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 33.61s
- Batch 4/5: Completed in 41.94s
- Batch 3/5: Completed in 26.47s
- Batch 2/5: Completed in 58.18s
- Batch 1/5: Completed in 64.97s


---

## Summary

**Completed:** 2026-02-05 17:24:50  
**Total Time:** 228.80s  
**Auto-Fixes Applied:** 6  
**Manual Interventions:** 4  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy for API Gateway REST API |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /modules/api_gateway/main.tf | Enabled X-Ray tracing for API Gateway stage |
| CKV_AWS_276 | module.api_gateway.aws_api_gateway_method_settings.all | /modules/api_gateway/main.tf | Disabled data trace logging in API Gateway method settings for security |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /modules/api_gateway/main.tf | Created request validator for API Gateway to validate request parameters and body |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /modules/dynamodb/main.tf | Enabled point-in-time recovery for DynamoDB table backup |
| CKV2_AWS_53 | aws_api_gateway_method.options | /modules/api_gateway/cors/main.tf | Added request_validator_id to enable request validation for OPTIONS method |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /modules/api_gateway/main.tf | Client certificate authentication not enabled |
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /modules/api_gateway/main.tf | API Gateway stage not protected by WAF |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /modules/route53/main.tf | DNSSEC signing not enabled for Route53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /modules/route53/main.tf | DNS query logging not enabled for Route53 hosted zone |
