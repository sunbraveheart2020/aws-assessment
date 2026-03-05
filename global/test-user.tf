resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = "sunfangyong2018@gmail.com"

  attributes = {
    email          = "sunfangyong2018@gmail.com"
    email_verified = "true"
  }

  temporary_password = "TempPass456!"
  force_alias_creation = false
  message_action       = "SUPPRESS"
}