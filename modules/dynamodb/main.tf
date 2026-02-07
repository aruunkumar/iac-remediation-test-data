# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Ensure DynamoDB Tables are encrypted using a KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires creating or referencing a KMS Customer Managed Key (CMK) which involves business decisions about:
#   - Key rotation policy and schedule
#   - Key administrators and users (IAM permissions)
#   - Multi-region key requirements
#   - Cost implications (CMK charges apply)
#   - Compliance and regulatory requirements for key management
# Fix: To enable KMS Customer Managed CMK encryption:
#   1. Create a KMS Customer Managed Key using aws_kms_key resource or reference an existing one
#   2. Define appropriate key policy with necessary IAM permissions
#   3. Add server_side_encryption block to the DynamoDB table:
#      server_side_encryption {
#        enabled     = true
#        kms_key_arn = aws_kms_key.dynamodb.arn  # or var.kms_key_arn
#      }
#   4. Ensure the DynamoDB service has permission to use the KMS key
#   5. Update variables.tf to accept kms_key_arn if using external key
# Example KMS key creation:
#   resource "aws_kms_key" "dynamodb" {
#     description             = "KMS key for DynamoDB table encryption"
#     deletion_window_in_days = 10
#     enable_key_rotation     = true
#   }
#   resource "aws_kms_alias" "dynamodb" {
#     name          = "alias/${var.table_name}-key"
#     target_key_id = aws_kms_key.dynamodb.key_id
#   }

# AGENT-FIXED: CKV_AWS_28 - Added point-in-time recovery (backup) for DynamoDB table
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
