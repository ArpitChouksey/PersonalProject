"""
hello_lambda.py

Single, minimal Lambda shared across the HTTP, WebSocket, REST,
and OpenAPI-import test scenarios. Just returns a fixed greeting
-- enough to confirm the integration actually fired, without
needing separate functions per test.
"""

import json


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "hey this is test http apis"}),
    }
