from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.tool_registry import get_all_tools
from app.llm_agent import DockerLLMAgent


app = FastAPI(
    title="Docker Agent API",
    version="1.0.0",
    description="AI-powered Docker and Linux operations agent",
)


# ---------------------------------------------------------
# CORS
# ---------------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------
# Request model
# ---------------------------------------------------------

class ChatRequest(BaseModel):
    message: str


# ---------------------------------------------------------
# Tools
# ---------------------------------------------------------

tools = get_all_tools()

agent = DockerLLMAgent(
    tools=tools
)


# ---------------------------------------------------------
# Root
# ---------------------------------------------------------

@app.get("/")
def root():

    return {
        "status": "SUCCESS",
        "message": "Docker Agent API is running",
    }


# ---------------------------------------------------------
# Health
# ---------------------------------------------------------

@app.get("/health")
def health():

    return {
        "status": "UP",
    }


# ---------------------------------------------------------
# Tools
# ---------------------------------------------------------

@app.get("/tools")
def list_tools():

    return {
        "status": "SUCCESS",
        "tools": list(tools.keys()),
    }


# ---------------------------------------------------------
# Chat
# ---------------------------------------------------------

@app.post("/agent/chat")
def chat(request: ChatRequest):

    message = request.message.strip()

    if not message:

        raise HTTPException(
            status_code=400,
            detail="Message cannot be empty",
        )

    try:

        result = agent.run(message)

        return result

    except Exception as exc:

        raise HTTPException(
            status_code=500,
            detail=str(exc),
        )
