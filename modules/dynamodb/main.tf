# DynamoDB module - Creates DynamoDB tables

# TODO: CKV_AWS_119 - Enable DynamoDB encryption using KMS Customer Managed CMK
# Resource: aws_dynamodb_table.main_table
# Reason: Requires creating or referencing a KMS customer-managed key. Multi-resource coordination and organizational key management decisions needed.
# Fix: Create a KMS key and configure server-side encryption:
#
# 1. Create KMS key for DynamoDB encryption:
#    resource "aws_kms_key" "dynamodb_key" {
#      description             = "KMS key for DynamoDB table encryption"
#      deletion_window_in_days = 10
#      enable_key_rotation     = true
#
#      tags = {
#        Name = "dynamodb-encryption-key"
#      }
#    }
#
#    resource "aws_kms_alias" "dynamodb_key_alias" {
#      name          = "alias/dynamodb-${var.table_name}"
#      target_key_id = aws_kms_key.dynamodb_key.key_id
#    }
#
# 2. Add server_side_encryption block to DynamoDB table:
#    server_side_encryption {
#      enabled     = true
#      kms_key_arn = aws_kms_key.dynamodb_key.arn
#    }
#
# 3. Optional: Add KMS key policy to control access:
#    resource "aws_kms_key_policy" "dynamodb_key_policy" {
#      key_id = aws_kms_key.dynamodb_key.id
#      policy = jsonencode({
#        Version = "2012-10-17"
#        Statement = [
#          {
#            Sid    = "Enable IAM User Permissions"
#            Effect = "Allow"
#            Principal = {
#              AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#            }
#            Action   = "kms:*"
#            Resource = "*"
#          },
#          {
#            Sid    = "Allow DynamoDB to use the key"
#            Effect = "Allow"
#            Principal = {
#              Service = "dynamodb.amazonaws.com"
#            }
#            Action = [
#              "kms:Decrypt",
#              "kms:DescribeKey",
#              "kms:CreateGrant"
#            ]
#            Resource = "*"
#          }
#        ]
#      })
#    }

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
