# VPC (minimal, public-only to avoid NAT Gateway cost)
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_execution_role" {
  name = "${var.name}-${var.region}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Custom inline policy: allow publishing to BOTH SNS topics
resource "aws_iam_role_policy" "ecs_task_sns_publish" {
  name = "${var.name}-${var.region}-ecs-task-sns-publish"
  role = aws_iam_role.task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          var.sns_topic_arn,
          var.sns_topic_assessment_arn
        ]
      }
    ]
  })
}

# Attach AWS-managed ECS execution policy (pull images, write logs)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task Definition (amazon/aws-cli)
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "awscli"
      image     = "amazon/aws-cli"
      essential = true
      command = [
        "sh", "-c",
        <<-EOF
          aws sns publish \
            --topic-arn ${var.sns_topic_arn} \
            --message '${jsonencode({
              email  = var.email,
              source = "ECS",
              region = var.region,
              repo   = var.repo
            })}'

          aws sns publish \
            --topic-arn ${var.sns_topic_assessment_arn} \
            --message '${jsonencode({
              email  = var.email,
              source = "ECS",
              region = var.region,
              repo   = var.repo
            })}'
        EOF
      ]
    }
  ])
}
