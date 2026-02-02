# Remediation Report

**Scan ID:** 175686a4-9ec0-4c80-8646-02a2a750d515  
**Started:** 2026-02-02 19:15:06  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 44.88s
- Batch 4/5: Completed in 78.90s
- Batch 3/5: Completed in 47.24s
- Batch 2/5: Completed in 79.28s
- Batch 1/5: Completed in 82.46s


---

## Summary

**Completed:** 2026-02-02 19:20:38  
**Total Time:** 336.46s  
**Auto-Fixes Applied:** 11  
**Manual Interventions:** 2  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy for API Gateway REST API |
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added cache cluster configuration with variable control |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for the API Gateway stage |
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added access_log_settings block for access logging |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added method settings to define logging level for API Gateway stage |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added client_certificate_id for client certificate authentication |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Added request validator for API Gateway method validation |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Added server_side_encryption block with KMS Customer Managed CMK |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery (backup) for DynamoDB table |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | Enabled DNS query logging for Route 53 hosted zone |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | Added request_validator_id to enable request validation for OPTIONS method |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Ensure public API gateway are protected by WAF |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | Ensure DNSSEC signing is enabled for Route 53 public hosted zones |
