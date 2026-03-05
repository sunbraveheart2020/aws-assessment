import os
import json
import boto3

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

TABLE_NAME = os.environ["TABLE_NAME"]
SNS_TOPIC = os.environ["SNS_TOPIC"]
SNS_TOPIC_ASSESSMENT = os.environ["SNS_TOPIC_ASSESSMENT"]
EMAIL = os.environ["EMAIL"]
REPO = os.environ["REPO"]

def lambda_handler(event, context):
    region = os.environ["AWS_REGION"]

    # Write to DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item={
        "id": context.aws_request_id,
        "region": region,
        "timestamp": context.get_remaining_time_in_millis()
    })

    # Publish SNS verification message
    payload = {
        "email": EMAIL,
        "source": "Lambda",
        "region": region,
        "repo": REPO
    }

   # Publish to my testing email SNS topic
    sns.publish(
        TopicArn=SNS_TOPIC,
        Message=json.dumps(payload)
    )

    # Publish to assessment SNS topic
    sns.publish(
        TopicArn=SNS_TOPIC_ASSESSMENT,
        Message=json.dumps(payload)
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"region": region})
    }
