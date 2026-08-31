from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.agent import run_agent


# ============================================================
# FastAPI Application
# ============================================================

app = FastAPI(
    title="Kubernetes AI Agent",
    description="Bedrock + MCP + Kubernetes",
    version="1.0.0",
)


# ============================================================
# CORS
# ============================================================

# React is running on port 5174.
# FastAPI is running on port 8000.

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5174",
        "http://127.0.0.1:5174",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# Request / Response Models
# ============================================================

class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    response: str


# ============================================================
# Health Check
# ============================================================

@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "kubernetes-ai-agent",
    }


# ============================================================
# Chat Endpoint
# ============================================================

@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):

    print("\n======================================")
    print("[API] Chat request received")
    print("======================================")
    print(f"[API] User: {request.message}")

    try:
        # ----------------------------------------------------
        # Send user request to the Kubernetes Agent
        #
        # agent.py handles:
        #
        # User
        #   ↓
        # Bedrock
        #   ↓
        # MCP tool selection
        #   ↓
        # Kubernetes MCP Server
        #   ↓
        # Kubernetes cluster
        #   ↓
        # Bedrock final response
        # ----------------------------------------------------

        answer = await run_agent(request.message)

        # ----------------------------------------------------
        # Safety check
        #
        # Prevent Pydantic validation error if run_agent()
        # unexpectedly returns None.
        # ----------------------------------------------------

        if answer is None:
            answer = "The agent did not return a response."

        # Make sure the response is a string.
        answer = str(answer)

        print("\n[API] Agent response:")
        print(answer)

        return ChatResponse(
            response=answer
        )

    except Exception as e:

        print("\n======================================")
        print("[API] ERROR")
        print("======================================")
        print(repr(e))

        return ChatResponse(
            response=f"Agent error: {str(e)}"
        )


# ============================================================
# Root Endpoint
# ============================================================

@app.get("/")
async def root():
    return {
        "service": "Kubernetes AI Agent",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "chat": "/api/chat",
        },
    }
