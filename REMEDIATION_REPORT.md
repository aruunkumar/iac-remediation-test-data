# Remediation Report

**Scan ID:** 476a2f6b-06d0-4732-be7c-24c6a024611d  
**Started:** 2026-02-02 19:33:35  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 49.68s
- Batch 4/5: Completed in 56.27s
- Batch 3/5: Completed in 52.33s
- Batch 2/5: Completed in 73.32s
- Batch 1/5: Completed in 77.73s


---

## Summary

**Completed:** 2026-02-02 19:38:44  
**Total Time:** 312.99s  
**Auto-Fixes Applied:** 7  
**Manual Interventions:** 6  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy for API Gateway REST API |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for API Gateway stage |
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added access_log_settings for API Gateway stage |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added method settings to define logging level for API Gateway stage |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added client_certificate_id to enable client certificate authentication |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Added request_validator_id to enable request validation |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery for DynamoDB table |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway caching is not enabled |
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway is not protected by WAF |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | DynamoDB table is not encrypted with KMS Customer Managed CMK |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNSSEC signing is not enabled for Route53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNS query logging is not enabled for Route53 hosted zone |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | Request validation is not configured for OPTIONS method |
