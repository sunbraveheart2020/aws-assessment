This repository contains a fully automated, multi‑region AWS deployment using Terraform. It provisions a global Cognito + SNS layer and two independent regional stacks (us‑east‑1 and eu‑west‑1) containing API Gateway, Lambda, DynamoDB, and ECS Fargate workloads.

Note: SNS layer is used for self-testing to ensure that received emails are accurate.

# Repository Structure
.
├── global/                     # Cognito + SNS (deployed once)
│   ├── cognito.tf
│   ├── sns.tf                  # Used for self-testing
│   ├── variables.tf
│   ├── providers.tf
│   └── outputs.tf
│
├── regional/
│   ├── us-east-1/             # Region 1 stack - us-east-1
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   └── data.tf
│   ├── eu-west-1/             # Region 2 stack - eu-west-1
│   │    ├── main.tf
│   │    ├── variables.tf
│   │    ├── providers.tf
│   │    └── data.tf
│   │
│   └── modules/               # shared modules for Region 1 and Region 2
│       ├── lambda_greet/
│       ├── lambda_dispatch/
│       ├── dynamodb/
│       ├── ecs/
│       └── api_gateway/
│
├── testscript/
│    └── testscript.py      # Automated test script
│
└── workflows/
    └── deploy.yml          # GitHub Actions CI/CD Automation


# Deployment Guide

## Prerequisites
- Terraform ≥ 1.5 and installed
- AWS CLI configured (`aws configure`)
- Python 3 installed (for running the test script)
- An AWS IAM user or role with permissions to deploy Cognito, SNS, Lambda, API Gateway, DynamoDB, and ECS


## Deploying the Global Stack (Cognito + SNS)

### Directory
`global/`

### Steps
```bash
cd global
terraform init
terraform apply
```

### Record the outputs:
`user_pool_id`
`user_pool_client_id`
`sns_topic_arn`

These values are automatically consumed by the regional stacks via `terraform_remote_state`.


## Deploying the Regional Stacks (API Gateway + Lambda + DynamoDB + ECS Fargate)

### Region 1: us‑east‑1

#### Directory:  
`regional/us-east-1/`

#### Steps
```bash
cd regional/us-east-1
terraform init
terraform apply
```

#### Record the outputs:
`api_endpoint`

### Region 2: eu-west-1

#### Directory:  
`regional/eu-west-1/`

#### Steps
```bash
cd regional/eu-west-1
terraform init
terraform apply
```

#### Record the outputs:
`api_endpoint`

## Running the Automated Test Script
The test script validates the entire multi‑region deployment by:

`Authenticating with Cognito to obtain a JWT`

`Calling /greet concurrently in both regions`

`Calling /dispatch concurrently in both regions`

`Measuring latency and asserting that the returned region matches the endpoint`

### Run the Test

#### Directory
`testscript/`

#### Steps
```bash
cd testscript
python3 testscript.py
```

## CI/CD Automation (GitHub Actions)
A GitHub Actions workflow is included under:
`workflows/deploy.yml`

It defines:

`Terraform fmt`

`Terraform validate`

`Security scan (tfsec or checkov)`

`Terraform plan`

`A placeholder step for running the automated test script`

## Cleanup (Optional)
Destroy regional stacks:

#### Directory
`regional/us-east-1`

#### Steps
```bash
cd regional/us-east-1
terraform destroy
```
#### Directory
`regional/eu-west-1`

#### Steps
```bash
cd regional/eu-west-1
terraform destroy
```

Destroy the global stack:

#### Directory
`global/`

#### Steps
```bash
cd global
terraform destroy
```
