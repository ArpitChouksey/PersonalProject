from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.agent.agent import run_agent


app = FastAPI(
    title="Kubernetes Agent"
)


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,

    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",

        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],

    allow_credentials=True,

    allow_methods=["*"],

    allow_headers=["*"],
)


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get("/")
def health_check():

    return {
        "status": "Kubernetes Agent is running"
    }


# ============================================================
# CHAT
# ============================================================

@app.post("/agent/chat")
def chat(request: dict):

    message = request.get(
        "message",
        ""
    )

    return run_agent(
        message
    )
