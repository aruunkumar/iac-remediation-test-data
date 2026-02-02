# Remediation Report

**Scan ID:** 36a9db0d-212c-4ff2-84d2-c2ba73aa306a  
**Started:** 2026-02-02 19:23:32  
**Findings:** 13  
**Batches:** 5

---

## Progress

- Batch 5/5: Completed in 37.76s
- Batch 4/5: Completed in 49.07s
- Batch 3/5: Completed in 32.60s
- Batch 2/5: Completed in 74.58s
- Batch 1/5: Completed in 72.33s


---

## Summary

**Completed:** 2026-02-02 19:27:58  
**Total Time:** 270.04s  
**Auto-Fixes Applied:** 7  
**Manual Interventions:** 6  
**Errors:** 0

---

## Auto-Fixed Issues

| Check ID | Resource | File | What Changed |
|----------|----------|------|--------------|
| CKV_AWS_237 | module.api_gateway.aws_api_gateway_rest_api.api | /iac-remediation-test-data/modules/api_gateway/main.tf | Added lifecycle block with create_before_destroy to ensure zero-downtime updates |
| CKV_AWS_120 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled cache cluster for API Gateway stage with configurable size |
| CKV_AWS_73 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Enabled X-Ray tracing for distributed request tracking and monitoring |
| CKV2_AWS_51 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | Added client certificate authentication for secure backend communication |
| CKV2_AWS_53 | module.api_gateway.aws_api_gateway_method.user_get | /iac-remediation-test-data/modules/api_gateway/main.tf | Created request validator to validate request body and parameters |
| CKV_AWS_28 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | Enabled point-in-time recovery for DynamoDB table backup and restore capability |
| CKV2_AWS_53 | aws_api_gateway_method.options | /iac-remediation-test-data/modules/api_gateway/cors/main.tf | Added request_validator_id to OPTIONS method |

---

## Manual Intervention Required

| Check ID | Resource | File | Action Needed |
|----------|----------|------|---------------|
| CKV_AWS_76 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway Access Logging not enabled |
| CKV2_AWS_4 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway logging level not defined |
| CKV2_AWS_29 | module.api_gateway.aws_api_gateway_stage.prod | /iac-remediation-test-data/modules/api_gateway/main.tf | API Gateway not protected by WAF |
| CKV_AWS_119 | module.dynamodb.aws_dynamodb_table.main_table | /iac-remediation-test-data/modules/dynamodb/main.tf | DynamoDB table not encrypted with KMS Customer Managed CMK |
| CKV2_AWS_38 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNSSEC signing not enabled for Route53 hosted zone |
| CKV2_AWS_39 | module.route53.aws_route53_zone.hosted_zone | /iac-remediation-test-data/modules/route53/main.tf | DNS query logging not enabled for Route53 hosted zone |
