# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Enable DynamoDB encryption using KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires a KMS Customer Managed Key (CMK) ARN to be specified; organization must decide which key to use
# Fix: To enable KMS encryption with a customer managed key:
#   1. Create or identify an existing KMS CMK for DynamoDB encryption
#   2. Add a server_side_encryption block to the table configuration:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = "arn:aws:kms:region:account-id:key/key-id"
#      }
#   3. Ensure the KMS key policy allows DynamoDB service to use the key
#   4. Consider creating a variable for the KMS key ARN for reusability

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
