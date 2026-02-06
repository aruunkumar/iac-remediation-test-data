# DynamoDB module - Creates DynamoDB tables

# AGENT-FIXED: CKV_AWS_119 - Created KMS Customer Managed Key for DynamoDB table encryption with key rotation enabled
resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB table encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.table_name}-encryption-key"
  }
}

# AGENT-FIXED: CKV_AWS_119 - Created KMS key alias for easier identification and management
resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/${var.table_name}-key"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

# AGENT-FIXED: CKV_AWS_28 - Enabled point-in-time recovery for backup and restore capabilities
# AGENT-FIXED: CKV_AWS_119 - Added server_side_encryption block with Customer Managed KMS key
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

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
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
