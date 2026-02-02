# DynamoDB module - Creates DynamoDB tables

# AGENT-FIXED: CKV_AWS_119 - Added server_side_encryption block with KMS Customer Managed CMK
# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery (backup) for DynamoDB table
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

  # Enable point-in-time recovery for backup capability
  point_in_time_recovery {
    enabled = true
  }

  # Enable encryption at rest with KMS Customer Managed CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
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
