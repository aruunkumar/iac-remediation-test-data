# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table should use customer-managed KMS key for encryption
# Resource: aws_dynamodb_table.main_table
# Reason: Requires decision on KMS key management strategy and key ARN
# Fix: To enable customer-managed KMS encryption:
#   1. Create or identify an existing KMS key for DynamoDB encryption
#   2. Ensure the KMS key policy allows DynamoDB service to use it
#   3. Add the server_side_encryption block to this resource:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or reference to existing key
#      }
#   4. If creating a new KMS key, example configuration:
#      resource "aws_kms_key" "dynamodb" {
#        description             = "KMS key for DynamoDB encryption"
#        deletion_window_in_days = 10
#        enable_key_rotation     = true
#      }
#      resource "aws_kms_alias" "dynamodb" {
#        name          = "alias/dynamodb-${var.table_name}"
#        target_key_id = aws_kms_key.dynamodb.key_id
#      }
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table
resource "aws_dynamodb_table" "main_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "alias"
  range_key    = "trainingId"

  attribute {
    name = "alias"
    type = "S"
  }

  attribute {
    name = "trainingId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}
