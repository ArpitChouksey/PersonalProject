from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.agent.agent import TerraformAgent

app = FastAPI(
    title="Terraform Agent",
    description="Agentic Infrastructure Assistant",
    version="1.0.0",
)

# Allow React/Vite frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

agent = TerraformAgent()


@app.get("/")
def root():
    return {
        "status": "success",
        "message": "Terraform Agent API is running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "terraform-agent",
    }


@app.post("/agent/chat")
def chat(request: dict):
    message = request.get("message", "")

    return agent.chat(message)
