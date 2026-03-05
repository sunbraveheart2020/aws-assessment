import os
import json
import boto3

ecs = boto3.client("ecs")
sns = boto3.client("sns")

CLUSTER_ARN = os.environ["CLUSTER_ARN"]
TASK_DEFINITION_ARN = os.environ["TASK_DEFINITION_ARN"]
SUBNET_ID = os.environ["SUBNET_ID"]
SNS_TOPIC = os.environ["SNS_TOPIC"]
SNS_TOPIC_ASSESSMENT = os.environ["SNS_TOPIC_ASSESSMENT"]
EMAIL = os.environ["EMAIL"]
REPO = os.environ["REPO"]

def lambda_handler(event, context):
    region = os.environ["AWS_REGION"]

    # Run ECS Fargate task
    ecs.run_task(
        cluster=CLUSTER_ARN,
        taskDefinition=TASK_DEFINITION_ARN,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": [SUBNET_ID],
                "assignPublicIp": "ENABLED"
            }
        }
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"region": region})
    }
