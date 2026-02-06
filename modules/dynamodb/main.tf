# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires a KMS Customer Managed Key (CMK) ARN which must be created separately and is organization-specific
# Fix: To remediate this finding:
#   1. Create a KMS Customer Managed Key (CMK) using aws_kms_key resource or use an existing one
#   2. Add the KMS key ARN to the variables or provide it directly
#   3. Uncomment and configure the server_side_encryption block below
#   4. Update the kms_key_arn with your KMS key ARN
#   Example:
#     server_side_encryption {
#       enabled     = true
#       kms_key_arn = var.kms_key_arn  # or aws_kms_key.dynamodb.arn
#     }
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

  # Uncomment and configure after creating/providing KMS key ARN
  # server_side_encryption {
  #   enabled     = true
  #   kms_key_arn = var.kms_key_arn
  # }
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
