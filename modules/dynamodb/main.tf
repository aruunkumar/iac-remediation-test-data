# DynamoDB module - Creates DynamoDB tables

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table
# TODO: CKV_AWS_119 - DynamoDB table is not encrypted with a KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Encryption with KMS Customer Managed CMK requires creating or selecting a specific KMS key, which is an organizational decision that depends on key management policies
# Fix: To enable KMS Customer Managed CMK encryption, complete the following steps:
#   1. Create a KMS key using aws_kms_key resource or identify an existing KMS key ARN
#   2. Ensure the KMS key policy allows DynamoDB service to use the key for encryption/decryption
#   3. Add server_side_encryption block to the DynamoDB table with:
#      - enabled = true
#      - kms_key_arn = aws_kms_key.<key_name>.arn (or your existing KMS key ARN)
#   4. Consider key rotation policies and access controls based on your security requirements
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
