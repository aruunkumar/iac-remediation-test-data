# DynamoDB module - Creates DynamoDB tables

# Data source to get current AWS account ID for KMS policy
data "aws_caller_identity" "current" {}

# AGENT-FIXED: CKV_AWS_119 - Created KMS key for DynamoDB encryption using customer managed CMK
# AGENT-FIXED: CKV2_AWS_64 - Added explicit KMS key policy with root account access and DynamoDB service permissions
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB table encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-dynamodb"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB to use the key"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "dynamodb.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "dynamodb-encryption-key"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.table_name}-encryption"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# AGENT-FIXED: CKV_AWS_119 - Enabled server-side encryption with customer managed KMS key
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

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
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
