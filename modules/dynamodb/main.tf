# DynamoDB module - Creates DynamoDB tables

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for DynamoDB table
# TODO: CKV_AWS_119 - DynamoDB table is not encrypted with KMS Customer Managed CMK
# Resource: module.dynamodb.aws_dynamodb_table.main_table
# Reason: Requires creation or specification of a KMS Customer Managed Key (CMK) with appropriate policies
# Fix: To enable KMS encryption with Customer Managed CMK:
#   1. Create an aws_kms_key resource or reference an existing KMS key ARN
#   2. Configure the KMS key policy to allow DynamoDB service to use the key
#   3. Add server_side_encryption block to the table with kms_key_arn specified
#   4. Example:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or var.kms_key_arn
#      }
#   5. Note: Using a customer managed key incurs additional KMS costs
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
    enabled = var.enable_point_in_time_recovery
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
