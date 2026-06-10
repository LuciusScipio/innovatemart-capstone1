resource "aws_iam_user" "dev_user" {
  name = "bedrock-dev-view"
  tags = { Project = "karatu-2025-capstone" }
}

# Attach Managed AWS Policy
resource "aws_iam_user_policy_attachment" "read_only" {
  user       = aws_iam_user.dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Inline policy to allow PutObject for the Asset Processor Bucket
resource "aws_iam_user_policy" "s3_put_access" {
  name = "BedrockAssetsPutAccess"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["arn:aws:s3:::bedrock-assets-alt-soe-25-3343/*"]
      }
    ]
  })
}


