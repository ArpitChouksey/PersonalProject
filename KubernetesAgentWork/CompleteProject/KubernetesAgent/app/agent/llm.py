# app/agent/llm.py

import json
import os
import requests


OLLAMA_HOST = os.getenv(
    "OLLAMA_HOST",
    "http://127.0.0.1:11434"
)

OLLAMA_URL = f"{OLLAMA_HOST}/api/chat"

MODEL_NAME = "llama3.2"


SYSTEM_PROMPT = """
You are Kubernetes Agent.

You are an AI assistant that can answer normal conversation
and perform Kubernetes operations.

Your job is to decide whether the user's request requires
a Kubernetes tool.

====================================================
NORMAL CONVERSATION
====================================================

For greetings, general conversation, or questions that do
not require Kubernetes cluster information, DO NOT call a tool.

Examples:

User: hello

Return:

{
  "type": "message",
  "message": "Hello! How can I help you with Kubernetes today?"
}

User: how are you?

Return:

{
  "type": "message",
  "message": "I'm doing well. How can I help with your Kubernetes cluster?"
}

====================================================
KUBERNETES REQUESTS
====================================================

If the user asks for actual Kubernetes information or asks
to perform a Kubernetes operation, select the appropriate tool.

Examples:

"show me nodes"

"show all nodes"

"list nodes"

"what nodes are running"

=> get_nodes

"show me pods"

"show all pods"

"list pods"

"show running pods"

"what pods are running"

=> get_all_pods

"show pods in default namespace"

"list pods in default"

=> get_pods

"show deployments"

"list deployments"

"show all deployments"

=> get_deployments

"show namespaces"

"list namespaces"

"show all Kubernetes namespaces"

=> list_namespaces

"create namespace agent-test"

=> create_namespace

"delete namespace agent-test"

=> delete_namespace

"describe pod nginx in namespace default"

=> describe_pod

"show logs for pod nginx in namespace default"

=> get_pod_logs

"scale deployment nginx to 3 replicas"

=> scale_deployment

"create deployment nginx using image nginx"

=> create_deployment

"create pod nginx using image nginx"

=> create_pod

"delete pod nginx"

=> delete_pod

"restart pod nginx"

=> restart_pod

"restart deployment nginx"

=> restart_deployment

====================================================
IMPORTANT
====================================================

Words such as:

show
show me
give me
share
list
display
tell me
what are
what is

DO NOT mean normal conversation.

If these words are followed by a Kubernetes resource or
Kubernetes operation, select the appropriate Kubernetes tool.

====================================================
RESPONSE FORMAT
====================================================

For normal conversation return ONLY valid JSON:

{
  "type": "message",
  "message": "your response"
}

For Kubernetes operations return ONLY valid JSON:

{
  "type": "tool_call",
  "tool": "tool_name",
  "arguments": {}
}

Never return markdown.

Never explain the tool call.

Never invent tool names.

Never invent Kubernetes data.

Use only tools provided in the tool list.
"""


def call_ollama(
    message: str,
    tools: dict
) -> dict:

    tool_descriptions = []

    for name, tool in tools.items():
        tool_descriptions.append({
            "name": name,
            "description": tool.get(
                "description",
                ""
            )
        })

    prompt = f"""
Available Kubernetes tools:

{json.dumps(tool_descriptions, indent=2)}

User request:

{message}

Return ONLY valid JSON according to the system instructions.
"""

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {
                "role": "system",
                "content": SYSTEM_PROMPT
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "stream": False,
        "options": {
            "temperature": 0
        }
    }

    response = requests.post(
        OLLAMA_URL,
        json=payload,
        timeout=120
    )

    response.raise_for_status()

    data = response.json()

    content = data["message"]["content"].strip()

    # Remove accidental markdown fences
    if content.startswith("```"):
        content = content.replace(
            "```json",
            ""
        ).replace(
            "```",
            ""
        ).strip()

    try:
        return json.loads(content)

    except json.JSONDecodeError:
        return {
            "type": "message",
            "message": content
        }


def call_llm(
    message: str,
    tools: dict
) -> dict:

    return call_ollama(
        message=message,
        tools=tools
    )
