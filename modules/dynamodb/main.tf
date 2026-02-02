# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - DynamoDB table is not encrypted with KMS Customer Managed CMK
# Resource: module.dynamodb.aws_dynamodb_table.main_table
# Reason: Requires a KMS Customer Managed Key (CMK) to be created or specified, which is an organizational decision
# Fix: To enable KMS encryption with Customer Managed Key:
#   1. Create a KMS key using aws_kms_key resource or reference an existing key
#   2. Add the following server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or reference to existing key
#      }
#   3. Ensure the KMS key policy allows DynamoDB service to use it
#   4. Consider key rotation policy and access controls
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for backup protection
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
