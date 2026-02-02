# Remediation Report

**Scan ID:** 65b7fced-143a-472e-9916-83beef0f3f41  
**Started:** 2026-02-02 18:54:33  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 39.52s
- Batch 4/5: Completed in 48.33s
- Batch 3/5: Completed in 28.81s
- Batch 2/5: Completed in 65.73s
- Batch 1/5: Completed in 60.12s


---

## Summary

**Completed:** 2026-02-02 18:58:36  
**Total Time:** 246.20s  
**Auto-Fixes Applied:** 7  
**Manual Interventions:** 6  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy for API Gateway REST API |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for API Gateway stage |
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added access logging configuration with CloudWatch log group |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added method settings with appropriate logging level |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added client certificate for mutual TLS authentication |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Added request validator to API Gateway method for request validation |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery for DynamoDB table |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway caching is not enabled |
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Public API Gateway is not protected by WAF |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | DynamoDB Tables are not encrypted using a KMS Customer Managed CMK |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNSSEC signing is not enabled for Route 53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNS query logging is not enabled for Route 53 hosted zone |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | Request validation is not configured for OPTIONS method |
