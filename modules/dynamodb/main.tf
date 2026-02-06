# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Brief description of the issue
# Resource: aws_dynamodb_table.main_table
# Reason: Requires decision on KMS key management - whether to create a new customer-managed CMK or use an existing one. Key policies and rotation settings are organization-specific.
# Fix: Specific steps to remediate:
#   1. Create or identify an existing KMS customer-managed key (CMK) for DynamoDB encryption
#   2. Ensure the KMS key policy allows DynamoDB service to use the key
#   3. Add the server_side_encryption block to the table configuration:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or reference to existing key
#      }
#   4. Consider enabling automatic key rotation for the KMS key
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for backup and restore capabilities
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
