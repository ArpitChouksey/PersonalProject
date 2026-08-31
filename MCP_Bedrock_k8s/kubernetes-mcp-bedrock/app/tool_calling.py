import boto3
from dotenv import load_dotenv

load_dotenv()

client = boto3.client(
    "bedrock-runtime",
    region_name="us-east-1"
)


# ============================================================
# TOOL
# ============================================================

def get_cluster_info():
    return {
        "cluster_name": "demo-cluster",
        "status": "ACTIVE",
        "nodes": 3
    }


# ============================================================
# TOOL DEFINITION FOR BEDROCK
# ============================================================

tools = [
    {
        "toolSpec": {
            "name": "get_cluster_info",
            "description": "Get information about the Kubernetes cluster.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {},
                    "required": []
                }
            }
        }
    }
]


# ============================================================
# FIRST REQUEST
# ============================================================

response = client.converse(
    modelId="amazon.nova-lite-v1:0",

    messages=[
        {
            "role": "user",
            "content": [
                {
                    "text": "What is the status of my Kubernetes cluster?"
                }
            ]
        }
    ],

    toolConfig={
        "tools": tools
    }
)

print(response)
