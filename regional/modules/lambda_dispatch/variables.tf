variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "task_definition_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "sns_topic_assessment_arn" {
  type = string
  default = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}

variable "email" {
  type = string
}

variable "repo" {
  type = string
}
