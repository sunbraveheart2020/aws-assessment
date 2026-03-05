resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-${var.region}-lambda-greet-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy: DynamoDB + SNS + CloudWatch Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.name}-${var.region}-lambda-greet-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          var.sns_topic_arn,
          var.sns_topic_assessment_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = "${var.name}-lambda-greet"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME   = var.dynamodb_table_name
      SNS_TOPIC    = var.sns_topic_arn
      SNS_TOPIC_ASSESSMENT  = var.sns_topic_assessment_arn
      EMAIL        = var.email
      REPO         = var.repo
    }
  }
}

# Zip the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file  = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/lambda.zip"
}


