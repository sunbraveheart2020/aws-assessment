resource "aws_sns_topic" "verification" {
  name = "candidate-verification-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.verification.arn
  protocol  = "email"
  endpoint  = var.email
}
