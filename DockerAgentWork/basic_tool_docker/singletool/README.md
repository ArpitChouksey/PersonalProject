Docker LLM Agent — Basic Interview Project
Overview

A very basic Agentic AI + Docker project using:

FastAPI — API layer
Ollama / Llama 3.2 — LLM
Python — tool execution
Docker CLI — container information

The user sends a natural-language request. The LLM identifies the intent and tells the application which action to perform. Python then executes the Docker command.

Flow
User
  ↓
FastAPI
  ↓
LLM (Llama 3.2)
  ↓
LIST_CONTAINERS
  ↓
Python Docker Tool
  ↓
docker ps -a
  ↓
Container List
Project Structure
basic_tool_docker/
│
└── main.py

Everything is intentionally kept inside one file for easy explanation during an interview.

Prerequisites

Check Python:

python3 --version

Check Docker:

docker --version

Check Ollama:

ollama --version

Check the Llama model:

ollama list

If the model is not available:

ollama pull llama3.2
1. Create Virtual Environment
cd basic_tool_docker
python3 -m venv .venv

Activate it:

source .venv/bin/activate
2. Install Dependencies
pip install fastapi uvicorn requests
3. Start Ollama
ollama run llama3.2

Keep Ollama running.

4. Start FastAPI

Open another terminal:

cd basic_tool_docker
source .venv/bin/activate

Run:

python -m uvicorn main:app --reload --port 8000

The API will be available at:

http://127.0.0.1:8000
Testing
Test 1 — Show all containers
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show me all containers"}'
Test 2 — Natural language
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"What containers are currently running?"}'
Test 3 — Informal request
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"currently running list?"}'
Test 4 — Different wording
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"Can you show me the Docker containers?"}'
Test 5 — Unsupported request
curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"Tell me a joke"}'

Expected:

{
  "action": "UNKNOWN",
  "message": "I don't know how to handle this request."
}
Direct Docker Test

You can verify the underlying Docker command directly:

docker ps -a

The agent executes this command when the LLM returns:

LIST_CONTAINERS
Example Response
{
  "action": "LIST_CONTAINERS",
  "result": "CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES..."
}
Interview Explanation

The key concept is that the LLM does not directly execute Docker commands.

The LLM decides the user's intent:

User
 ↓
LLM
 ↓
LIST_CONTAINERS
 ↓
Python Tool
 ↓
docker ps -a
 ↓
Result

You can explain:

"The LLM is responsible for understanding the user's natural-language request and selecting an action. The actual Docker operation is performed by a controlled Python tool. This separates reasoning from execution."

Complete Architecture
             ┌──────────────┐
             │     User     │
             └──────┬───────┘
                    │
                    │ Natural Language
                    ▼
             ┌──────────────┐
             │   FastAPI    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │ Llama 3.2    │
             │   Ollama     │
             └──────┬───────┘
                    │
                    │ LIST_CONTAINERS
                    ▼
             ┌──────────────┐
             │ Docker Tool  │
             └──────┬───────┘
                    │
                    │ docker ps -a
                    ▼
             ┌──────────────┐
             │    Docker    │
             └──────┬───────┘
                    │
                    │ Result
                    ▼
             ┌──────────────┐
             │     User     │
             └──────────────┘
Quick Start
cd basic_tool_docker
source .venv/bin/activate
python -m uvicorn main:app --reload --port 8000

Make sure Ollama is running separately:

ollama run llama3.2

Then test:

curl -X POST http://127.0.0.1:8000/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show me all containers"}'
