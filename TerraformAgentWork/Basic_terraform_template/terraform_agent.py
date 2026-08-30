import subprocess
import requests

from fastapi import FastAPI
from pydantic import BaseModel


# ============================================================
# CONFIGURATION
# ============================================================

TERRAFORM_WORKSPACE = (
    "/Users/arpitchouksey/Documents/PersonalProjects/"
    "ofcprodapigateway/workspace/workspaces-module/networking-testing"
)

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3.2"


# ============================================================
# FASTAPI
# ============================================================

app = FastAPI(title="Terraform Agent")


# ============================================================
# REQUEST MODEL
# ============================================================

class ChatRequest(BaseModel):
    message: str


# ============================================================
# TERRAFORM INIT TOOL
# ============================================================

def terraform_init():

    result = subprocess.run(
        ["terraform", "init"],
        cwd=TERRAFORM_WORKSPACE,
        capture_output=True,
        text=True
    )

    return {
        "status": "success" if result.returncode == 0 else "error",
        "tool": "terraform_init",
        "output": result.stdout if result.returncode == 0 else result.stderr
    }


# ============================================================
# TERRAFORM PLAN TOOL
# ============================================================

def terraform_plan():

    result = subprocess.run(
        ["terraform", "plan"],
        cwd=TERRAFORM_WORKSPACE,
        capture_output=True,
        text=True
    )

    return {
        "status": "success" if result.returncode == 0 else "error",
        "tool": "terraform_plan",
        "output": result.stdout if result.returncode == 0 else result.stderr
    }


# ============================================================
# OLLAMA
# ============================================================

def ask_ollama(prompt):

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False
        }
    )

    response.raise_for_status()

    return response.json()["response"]


# ============================================================
# CHAT ENDPOINT
# ============================================================

@app.post("/chat")
def chat(request: ChatRequest):

    message = request.message.lower()


    # --------------------------------------------------------
    # TERRAFORM INIT
    # --------------------------------------------------------

    if (
        "terraform init" in message
        or "initialize terraform" in message
        or "initialize terraform project" in message
    ):

        result = terraform_init()

        return {
            "user_message": request.message,
            "tool": "terraform_init",
            "result": result
        }


    # --------------------------------------------------------
    # TERRAFORM PLAN
    # --------------------------------------------------------

    if (
        "terraform plan" in message
        or "run terraform plan" in message
        or "show terraform plan" in message
        or "create terraform plan" in message
    ):

        result = terraform_plan()

        return {
            "user_message": request.message,
            "tool": "terraform_plan",
            "result": result
        }


    # --------------------------------------------------------
    # OTHERWISE ASK OLLAMA
    # --------------------------------------------------------

    answer = ask_ollama(request.message)

    return {
        "user_message": request.message,
        "tool": "ollama",
        "response": answer
    }
