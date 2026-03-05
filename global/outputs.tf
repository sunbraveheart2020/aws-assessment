output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.verification.arn
}
