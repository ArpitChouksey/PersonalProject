from fastapi import FastAPI
from pydantic import BaseModel
import requests
import os

app = FastAPI()

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3.2"

DOWNLOAD_DIR = os.path.expanduser(
    "~/Downloads/llm_docker_images"
)

os.makedirs(DOWNLOAD_DIR, exist_ok=True)


class ChatRequest(BaseModel):
    message: str


def ask_llm(message):

    prompt = f"""
You are a Dockerfile generator.

User request:
{message}

Generate ONLY the Dockerfile.

Do not return JSON.
Do not use markdown code fences.
Do not add explanations.

Create a valid Dockerfile based on the user's requirements.
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

    return response.json()["response"].strip()


@app.post("/chat")
def chat(request: ChatRequest):

    try:

        dockerfile = ask_llm(request.message)

        # Remove accidental markdown fences
        dockerfile = dockerfile.replace("```dockerfile", "")
        dockerfile = dockerfile.replace("```Dockerfile", "")
        dockerfile = dockerfile.replace("```", "")
        dockerfile = dockerfile.strip()

        file_path = os.path.join(
            DOWNLOAD_DIR,
            "Dockerfile-generated"
        )

        with open(file_path, "w") as file:
            file.write(dockerfile)

        return {
            "status": "SUCCESS",
            "file": file_path,
            "dockerfile": dockerfile
        }

    except Exception as e:

        return {
            "status": "ERROR",
            "message": str(e)
        }
