from fastapi import FastAPI
from pydantic import BaseModel
import requests
import subprocess

app = FastAPI()

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3.2"


class ChatRequest(BaseModel):
    message: str


def ask_llm(message):

    prompt = f"""
You are a Docker assistant.

User request:
{message}

Decide what the user wants.

If the user is asking to:
- list containers
- show containers
- see containers
- check containers
- get containers
- show running containers
- list running containers
- see currently running containers
- check currently running containers
- ask what containers are running
- ask for a currently running container list
- use informal wording such as "currently running list"

return exactly:
LIST_CONTAINERS

For anything else return exactly:
UNKNOWN

Return ONLY one of these:
LIST_CONTAINERS
UNKNOWN
"""

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL,
            "prompt": prompt,
            "stream": False
        }
    )

    response.raise_for_status()

    result = response.json()

    return result["response"].strip().upper()


def list_containers():

    result = subprocess.run(
        ["docker", "ps", "-a"],
        capture_output=True,
        text=True
    )

    return result.stdout.strip()


@app.post("/chat")
def chat(request: ChatRequest):

    action = ask_llm(request.message)

    if "LIST_CONTAINERS" in action:

        containers = list_containers()

        return {
            "action": "LIST_CONTAINERS",
            "result": containers
        }

    return {
        "action": "UNKNOWN",
        "message": "I don't know how to handle this request."
    }
