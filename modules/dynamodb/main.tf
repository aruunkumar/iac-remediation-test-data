# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table is not encrypted with KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: KMS encryption requires a customer-managed KMS key ARN which is organization-specific.
#         The key must be created and managed separately with appropriate key policies and access controls.
# Fix: To enable KMS CMK encryption:
#   1. Create a KMS key using aws_kms_key resource or use an existing customer-managed key
#   2. Ensure the KMS key policy allows DynamoDB service to use the key
#   3. Add server_side_encryption block to the table with the KMS key ARN
#   4. Example:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or var.kms_key_arn
#      }
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table backup
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

# resource "aws_dynamodb_table" "chat_history_table" {
#   name         = var.conversation_history_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "conversation_id"
#   range_key    = "user_id"
  
#   ttl {
#     attribute_name = "conversation_age"
#     enabled        = true
#   }

#   attribute {
#     name = "conversation_id"
#     type = "S"
#   }

#   attribute {
#     name = "user_id"
#     type = "N"
#   }
# }
