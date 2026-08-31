import os
import boto3
from dotenv import load_dotenv

load_dotenv()

client = boto3.client(
    "bedrock-runtime",
    region_name="us-east-1"
)

response = client.converse(
    modelId="amazon.nova-lite-v1:0",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "text": "Explain Kubernetes in one sentence."
                }
            ]
        }
    ]
)

print(response["output"]["message"]["content"][0]["text"])
