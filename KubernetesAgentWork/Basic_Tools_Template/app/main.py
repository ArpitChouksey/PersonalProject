import os
import subprocess

import ollama
from fastapi import FastAPI
from pydantic import BaseModel


# ============================================================
# FASTAPI
# ============================================================

app = FastAPI(
    title="Simple Kubernetes Agent"
)


# ============================================================
# OLLAMA CONFIG
# ============================================================

OLLAMA_HOST = os.getenv(
    "OLLAMA_HOST",
    "http://127.0.0.1:11434"
)

OLLAMA_MODEL = os.getenv(
    "OLLAMA_MODEL",
    "llama3.2"
)


# ============================================================
# REQUEST MODEL
# ============================================================

class ChatRequest(BaseModel):
    message: str


# ============================================================
# KUBECTL HELPER
# ============================================================

def run_kubectl(command):

    result = subprocess.run(
        ["kubectl"] + command,
        capture_output=True,
        text=True
    )

    if result.returncode != 0:

        return {
            "status": "error",
            "message": result.stderr.strip()
        }

    return {
        "status": "success",
        "output": result.stdout.strip()
    }


# ============================================================
# TOOL 1: GET PODS
# ============================================================

def get_pods(
    namespace: str = "default"
):

    return run_kubectl(
        [
            "get",
            "pods",
            "-n",
            namespace
        ]
    )


# ============================================================
# TOOL 2: DESCRIBE POD
# ============================================================

def describe_pod(
    name: str,
    namespace: str = "default"
):

    return run_kubectl(
        [
            "describe",
            "pod",
            name,
            "-n",
            namespace
        ]
    )


# ============================================================
# TOOL 3: GET POD LOGS
# ============================================================

def get_pod_logs(
    name: str,
    namespace: str = "default",
    tail_lines: int = 100
):

    return run_kubectl(
        [
            "logs",
            name,
            "-n",
            namespace,
            "--tail",
            str(tail_lines)
        ]
    )


# ============================================================
# OLLAMA TOOL DEFINITIONS
# ============================================================

TOOLS = [

    {
        "type": "function",

        "function": {

            "name": "get_pods",

            "description":
                "Get Kubernetes pods from a namespace.",

            "parameters": {

                "type": "object",

                "properties": {

                    "namespace": {
                        "type": "string",
                        "description":
                            "Kubernetes namespace"
                    }

                },

                "required": []
            }
        }
    },

    {
        "type": "function",

        "function": {

            "name": "describe_pod",

            "description":
                "Describe a Kubernetes pod.",

            "parameters": {

                "type": "object",

                "properties": {

                    "name": {
                        "type": "string",
                        "description":
                            "Name of the pod"
                    },

                    "namespace": {
                        "type": "string",
                        "description":
                            "Kubernetes namespace"
                    }

                },

                "required": [
                    "name"
                ]
            }
        }
    },

    {
        "type": "function",

        "function": {

            "name": "get_pod_logs",

            "description":
                "Get logs from a Kubernetes pod.",

            "parameters": {

                "type": "object",

                "properties": {

                    "name": {
                        "type": "string",
                        "description":
                            "Name of the pod"
                    },

                    "namespace": {
                        "type": "string",
                        "description":
                            "Kubernetes namespace"
                    },

                    "tail_lines": {
                        "type": "integer",
                        "description":
                            "Number of log lines"
                    }

                },

                "required": [
                    "name"
                ]
            }
        }
    }

]


# ============================================================
# TOOL EXECUTOR
# ============================================================

def execute_tool(
    tool_name,
    arguments
):

    if tool_name == "get_pods":

        return get_pods(
            namespace=arguments.get(
                "namespace",
                "default"
            )
        )

    if tool_name == "describe_pod":

        return describe_pod(
            name=arguments["name"],

            namespace=arguments.get(
                "namespace",
                "default"
            )
        )

    if tool_name == "get_pod_logs":

        return get_pod_logs(

            name=arguments["name"],

            namespace=arguments.get(
                "namespace",
                "default"
            ),

            tail_lines=arguments.get(
                "tail_lines",
                100
            )
        )

    return {
        "status": "error",
        "message":
            f"Unknown tool: {tool_name}"
    }


# ============================================================
# CHAT ENDPOINT
# ============================================================

@app.post("/agent/chat")
def chat(
    request: ChatRequest
):

    user_message = request.message


    # --------------------------------------------------------
    # CONNECT TO LOCAL OLLAMA
    # --------------------------------------------------------

    client = ollama.Client(
        host=OLLAMA_HOST
    )


    # --------------------------------------------------------
    # SEND USER MESSAGE TO OLLAMA
    # --------------------------------------------------------

    response = client.chat(

        model=OLLAMA_MODEL,

        messages=[

            {
                "role": "system",

                "content": """
You are a simple Kubernetes assistant.

Use the available tools when the user asks
about Kubernetes pods.

Available operations:

1. Get pods
2. Describe a pod
3. Get pod logs

Examples:

show pods

get pods in kube-system

describe pod nginx

show logs of nginx

get logs of nginx in default namespace

Always use a Kubernetes tool when
the user asks about pods.
"""
            },

            {
                "role": "user",

                "content": user_message
            }

        ],

        tools=TOOLS
    )


    # --------------------------------------------------------
    # IF OLLAMA DOES NOT SELECT A TOOL
    # --------------------------------------------------------

    if not response.message.tool_calls:

        return {

            "status": "success",

            "type": "message",

            "message":
                response.message.content
        }


    # --------------------------------------------------------
    # GET TOOL CALL
    # --------------------------------------------------------

    tool_call = response.message.tool_calls[0]


    tool_name = tool_call.function.name


    arguments = tool_call.function.arguments


    # --------------------------------------------------------
    # EXECUTE KUBERNETES TOOL
    # --------------------------------------------------------

    result = execute_tool(

        tool_name,

        arguments
    )


    # --------------------------------------------------------
    # RETURN RESULT
    # --------------------------------------------------------

    return {

        "status": result["status"],

        "tool": tool_name,

        "arguments": arguments,

        "result": result
    }


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/")
def root():

    return {

        "status": "running",

        "service":
            "Simple Kubernetes Agent"
    }
