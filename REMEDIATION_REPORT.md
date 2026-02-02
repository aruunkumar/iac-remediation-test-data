# Remediation Report

**Scan ID:** ecbac9fd-36d6-4339-bf05-db091907d900  
**Started:** 2026-02-02 18:53:37  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 35.81s
- Batch 4/5: Completed in 47.14s
- Batch 3/5: Completed in 32.13s
- Batch 2/5: Completed in 75.85s
- Batch 1/5: Completed in 64.28s


---

## Summary

**Completed:** 2026-02-02 18:57:52  
**Total Time:** 258.93s  
**Auto-Fixes Applied:** 5  
**Manual Interventions:** 8  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy to ensure safe replacement of API Gateway |
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled API Gateway caching with default cache size of 0.5GB |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for API Gateway stage to track and analyze requests |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Added request_validator_id to enable request validation |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery for DynamoDB table to enable continuous backups |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway Access Logging is not enabled |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway stage logging level is not defined |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway endpoints should use client certificate authentication |
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Public API Gateway should be protected by WAF |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | DynamoDB table should use KMS Customer Managed CMK for encryption |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNSSEC signing is not enabled for Route53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNS query logging is not enabled for Route53 hosted zone |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | API Gateway request validation is not enabled for OPTIONS method |
