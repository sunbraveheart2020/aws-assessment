resource "null_resource" "create_confirmed_user" {
  provisioner "local-exec" {
    command = "aws cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.main.id} --username ${var.test_email} --user-attributes Name=email,Value=${var.test_email} Name=email_verified,Value=true --message-action SUPPRESS --region ${var.region} && aws cognito-idp admin-set-user-password --user-pool-id ${aws_cognito_user_pool.main.id} --username ${var.test_email} --password ${var.test_password} --permanent --region ${var.region}"
  }
}

