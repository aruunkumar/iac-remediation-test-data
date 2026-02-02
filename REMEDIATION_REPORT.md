# Remediation Report

**Scan ID:** 033db139-69a0-4bb6-adf8-80656b7e8e6f  
**Started:** 2026-02-02 19:15:05  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 44.58s
- Batch 4/5: Completed in 51.72s
- Batch 3/5: Completed in 41.71s
- Batch 2/5: Completed in 69.72s
- Batch 1/5: Completed in 57.75s


---

## Summary

**Completed:** 2026-02-02 19:19:30  
**Total Time:** 269.23s  
**Auto-Fixes Applied:** 9  
**Manual Interventions:** 4  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy for safe updates |
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled cache cluster for API Gateway stage |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for API Gateway stage |
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added access logging configuration with CloudWatch log group |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added method settings to define logging level for API Gateway stage |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added client certificate for secure backend communication |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Added request validator to validate API Gateway requests |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Added KMS encryption using customer managed key |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery for backup and restore capabilities |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway stage requires WAF protection |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNSSEC signing not enabled for Route 53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNS query logging not enabled for Route 53 hosted zone |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | Request validation not configured for OPTIONS method |
