import os

from dotenv import load_dotenv


load_dotenv()


OLLAMA_HOST = os.getenv(
    "OLLAMA_HOST",
    "http://127.0.0.1:11434"
)

OLLAMA_MODEL = os.getenv(
    "OLLAMA_MODEL",
    "llama3.2"
)

TERRAFORM_DIR = os.getenv(
    "TERRAFORM_DIR",
    "./terraform"
)
