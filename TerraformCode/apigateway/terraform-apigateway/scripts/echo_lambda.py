"""
echo_lambda.py

Minimal Lambda for TC-103 (Lambda proxy integration verification).

Deploy this as the function behind `employee-lambda` in
employee-http-test.yaml. It just echoes back exactly what API
Gateway sent it, so a single curl command lets you confirm the
proxy integration is forwarding body, query string, path
parameters, and headers correctly — instead of having to infer it
indirectly through a real business Lambda's behavior.

Deploy:
    zip echo_lambda.zip echo_lambda.py
    aws lambda create-function \
        --function-name employee-echo \
        --runtime python3.12 \
        --handler echo_lambda.handler \
        --role arn:aws:iam::<account_id>:role/lambda-basic-execution \
        --zip-file fileb://echo_lambda.zip \
        --region us-west-2

Then point employee-http-test.yaml's employee-lambda.config.function_arn
at the resulting function ARN before `terraform apply`.
"""

import json


def handler(event, context):

    response_body = {
        "http_method": event.get("requestContext", {}).get("http", {}).get("method"),
        "path": event.get("requestContext", {}).get("http", {}).get("path"),
        "raw_path": event.get("rawPath"),
        "path_parameters": event.get("pathParameters"),
        "query_string_parameters": event.get("queryStringParameters"),
        "headers": event.get("headers"),
        "body": event.get("body"),
        "is_base64_encoded": event.get("isBase64Encoded"),
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_body),
    }
