# Project9 Messaging – AI, RAG & MCP Platform

Project9 Messaging is an enterprise-oriented messaging and AI integration project demonstrating how a Java Spring Boot service and a Python FastAPI service can work with Model Context Protocol (MCP), Ollama LLMs, and Retrieval-Augmented Generation (RAG).

## Overview

The platform can:

- Expose REST APIs through FastAPI.
- Expose executable tools through an MCP server.
- Discover and execute MCP tools through an MCP client.
- Use Ollama and Llama 3.2 for local LLM inference.
- Use `nomic-embed-text` for document embeddings.
- Store and search embeddings using ChromaDB.
- Ground Project9-specific answers using RAG.
- Combine RAG context, MCP tool execution, and LLM responses.
- Provide a simple AI assistant UI.

---

## Architecture

```text
                         ┌──────────────────────┐
                         │       Web UI          │
                         │   Project9 Assistant  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      FastAPI         │
                         │   AI Orchestrator    │
                         └──────────┬───────────┘
                                    │
                  ┌─────────────────┼─────────────────┐
                  │                 │                 │
                  ▼                 ▼                 ▼
             ┌─────────┐      ┌───────────┐    ┌─────────────┐
             │ Ollama  │      │    RAG    │    │ MCP Client  │
             │Llama 3.2│      │           │    │             │
             └────┬────┘      └─────┬─────┘    └──────┬──────┘
                  │                 │                 │
                  │                 ▼                 ▼
                  │            ┌───────────┐    ┌─────────────┐
                  │            │ ChromaDB  │    │ MCP Server  │
                  │            └─────┬─────┘    └──────┬──────┘
                  │                 │                 │
                  │                 ▼          ┌──────┴───────┐
                  │        Project9 Documents   │              │
                  │                            ▼              ▼
                  │                     getSystemInfo     calculate
                  │
                  └──────────────────────────────────────────────┐
                                                                 ▼
                                                          Final Answer
```

---

## Technology Stack

| Component | Technology |
|---|---|
| Backend API | Python FastAPI |
| MCP Server | Python MCP SDK |
| MCP Transport | Streamable HTTP |
| MCP Client | Python MCP SDK |
| LLM Runtime | Ollama |
| LLM Model | Llama 3.2 |
| Embedding Model | nomic-embed-text |
| Vector Store | ChromaDB |
| Frontend | Simple web UI |
| Java Service | Spring Boot |
| API Server | Uvicorn |
| Package Management | Python virtual environment / uv |
| Testing | pytest |

---

## Project Structure

```text
fastapi-service/
│
├── app/
│   ├── api/
│   │   ├── calculator.py
│   │   ├── health.py
│   │   ├── system.py
│   │   └── users.py
│   │
│   ├── ai/
│   │   ├── __init__.py
│   │   ├── ai_service.py
│   │   ├── llm_service.py
│   │   ├── mcp_client.py
│   │   ├── router.py
│   │   ├── schemas.py
│   │   └── test_mcp_client.py
│   │
│   ├── mcp/
│   │   └── server.py
│   │
│   ├── rag/
│   │   ├── router.py
│   │   ├── rag_service.py
│   │   └── ...
│   │
│   ├── ui/
│   │   └── ...
│   │
│   ├── config/
│   │   └── settings.py
│   │
│   └── main.py
│
├── tests/
├── Dockerfile
├── pyproject.toml
├── requirements.txt
├── uv.lock
└── README.md
```

> File names can be adjusted to match the final implementation in the repository.

---

# 1. Prerequisites

Install:

- Python
- Ollama
- Git
- Docker Desktop (optional)
- Java/JDK for the Spring Boot service

Verify Python:

```bash
python --version
```

Verify Ollama:

```bash
ollama --version
```

---

# 2. Python Environment

Go to the FastAPI project:

```bash
cd fastapi-service
```

Create the virtual environment:

```bash
python -m venv .venv
```

Activate it on macOS/Linux:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Or:

```bash
pip install -e .
```

---

# 3. Ollama Setup

The project uses two local Ollama models.

### LLM

```bash
ollama pull llama3.2
```

### Embedding Model

```bash
ollama pull nomic-embed-text
```

Verify:

```bash
ollama list
```

Expected models:

```text
llama3.2:latest
nomic-embed-text:latest
```

Verify the Ollama API:

```bash
curl http://127.0.0.1:11434/api/tags
```

---

# 4. Start FastAPI

From the project root:

```bash
uvicorn app.main:app --reload --port 8000
```

Service:

```text
http://127.0.0.1:8000
```

Swagger UI:

```text
http://127.0.0.1:8000/docs
```

---

# 5. Health Check

```bash
curl http://127.0.0.1:8000/health
```

Expected:

```json
{
  "service": "fastapi-service",
  "status": "UP"
}
```

---

# 6. MCP Server

The FastAPI application exposes the MCP server through Streamable HTTP.

Endpoint:

```text
http://127.0.0.1:8000/mcp/
```

Current tools:

### `getSystemInfo`

Returns information about the FastAPI service.

### `calculate`

Supports:

```text
add
subtract
multiply
divide
```

---

## MCP Initialization

```bash
curl -i -X POST http://127.0.0.1:8000/mcp/   -H "Content-Type: application/json"   -H "Accept: application/json, text/event-stream"   -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-11-25",
      "capabilities": {},
      "clientInfo": {
        "name": "curl-test",
        "version": "1.0.0"
      }
    }
  }'
```

The response returns an `mcp-session-id`.

Save that session ID for manual MCP requests.

---

## MCP Tool Discovery

Replace `<SESSION_ID>`:

```bash
curl -i -X POST http://127.0.0.1:8000/mcp/   -H "Content-Type: application/json"   -H "Accept: application/json, text/event-stream"   -H "Mcp-Session-Id: <SESSION_ID>"   -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list",
    "params": {}
  }'
```

Expected tools:

```text
getSystemInfo
calculate
```

---

## MCP Tool Execution

```bash
curl -i -X POST http://127.0.0.1:8000/mcp/   -H "Content-Type: application/json"   -H "Accept: application/json, text/event-stream"   -H "Mcp-Session-Id: <SESSION_ID>"   -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "calculate",
      "arguments": {
        "operation": "add",
        "a": 100,
        "b": 250
      }
    }
  }'
```

Expected result:

```text
350
```

---

# 7. MCP Client Test

The project contains an MCP client that connects to the MCP server.

Run:

```bash
python -m app.ai.test_mcp_client
```

Expected:

```text
Available tools:
- getSystemInfo
- calculate

Tool result:
...
```

This verifies:

```text
MCP Client
    ↓
Streamable HTTP
    ↓
MCP Server
    ↓
calculate
```

---

# 8. AI / Ollama

The AI API is:

```text
POST /ai/chat
```

Test:

```bash
curl -X POST http://127.0.0.1:8000/ai/chat   -H "Content-Type: application/json"   -d '{
    "message": "What is 10 + 10?"
  }'
```

---

# 9. LLM + MCP Tool Calling

The AI orchestration layer provides MCP tool definitions to Ollama.

Test:

```bash
curl -X POST http://127.0.0.1:8000/ai/chat   -H "Content-Type: application/json"   -d '{
    "message": "You MUST use the calculate MCP tool to multiply 125 by 8. Do not calculate it yourself."
  }'
```

Expected:

```text
The result of multiplying 125 by 8 is 1000.
```

The actual flow is:

```text
User
  ↓
FastAPI /ai/chat
  ↓
AIService
  ↓
Ollama
  ↓
Structured tool call
  ↓
MCP Client
  ↓
MCP Server
  ↓
calculate
  ↓
1000
  ↓
Ollama
  ↓
Final response
```

---

# 10. RAG

The RAG layer uses:

```text
Ollama
   │
   └── nomic-embed-text
            │
            ▼
        Embeddings
            │
            ▼
         ChromaDB
```

Project documentation is ingested into the vector store.

---

## RAG Ingestion

```bash
curl -X POST http://127.0.0.1:8000/rag/ingest
```

Example:

```json
{
  "documents": 1,
  "chunks": 2
}
```

---

## RAG Search

```bash
curl -X POST http://127.0.0.1:8000/rag/search   -H "Content-Type: application/json"   -d '{
    "query": "How does the Python FastAPI service expose MCP?",
    "top_k": 3
  }'
```

The search should retrieve Project9 documentation containing information such as:

```text
The Python service exposes a Model Context Protocol server
through Streamable HTTP.
```

---

# 11. RAG + LLM

The AI orchestration layer retrieves relevant documentation before generating a Project9-specific answer.

Test:

```bash
curl -X POST http://127.0.0.1:8000/ai/chat   -H "Content-Type: application/json"   -d '{
    "message": "According to the Project9 documentation, how does the Python FastAPI service expose MCP?"
  }'
```

Expected answer:

```text
According to the Project9 documentation, the Python FastAPI
service exposes the MCP server through Streamable HTTP.
```

Flow:

```text
User question
      ↓
RAG search
      ↓
ChromaDB
      ↓
Relevant documentation
      ↓
Ollama
      ↓
Project-specific answer
```

---

# 12. Combined RAG + MCP

Target flow:

```text
                    User Prompt
                         │
                         ▼
                  AI Orchestrator
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
           RAG                     Ollama
             │                       │
             ▼                       │
         ChromaDB                    │
             │                       │
             ▼                       │
      Project9 Context               │
             │                       │
             └───────────┬───────────┘
                         │
                         ▼
                   Tool Decision
                         │
                         ▼
                    MCP Client
                         │
                         ▼
                    MCP Server
                         │
                         ▼
                  MCP Tool Result
                         │
                         ▼
                       Ollama
                         │
                         ▼
                    Final Answer
```

Test:

```bash
curl -X POST http://127.0.0.1:8000/ai/chat   -H "Content-Type: application/json"   -d '{
    "message": "According to the Project9 documentation, explain how the Python FastAPI service exposes MCP. Then use the calculate MCP tool to multiply 125 by 8."
  }'
```

The final response should contain:

1. Project9 documentation retrieved through RAG.
2. The actual MCP calculation result.

---

# 13. How LLM Uses MCP Tools

The LLM receives MCP tool definitions from the AI orchestration layer.

Example:

```text
calculate
Description:
Perform a mathematical calculation.

Parameters:
operation
a
b
```

The LLM can decide whether a tool is appropriate.

For:

```text
"What is Project9 Messaging?"
```

the LLM can answer using RAG/LLM.

For:

```text
"Use the calculate MCP tool to multiply 125 by 8."
```

the LLM can produce a structured tool call:

```json
{
  "name": "calculate",
  "arguments": {
    "operation": "multiply",
    "a": 125,
    "b": 8
  }
}
```

The application executes the MCP tool and sends the result back to Ollama for the final response.

---

# 14. UI

The project contains a simple AI assistant UI.

The UI sends requests to:

```text
POST /ai/chat
```

Example:

```text
User:
According to Project9 documentation, how does MCP work?

        ↓

FastAPI AI Orchestrator

        ↓

RAG + MCP + Ollama

        ↓

AI Assistant:
According to Project9 documentation...
```

---

# 15. MCP Inspector

For MCP development and debugging:

```bash
mcp dev app/mcp/server.py --with-editable .
```

The MCP Inspector can be used to:

- Discover MCP tools.
- Inspect tool schemas.
- Execute tools manually.
- Verify MCP server connectivity.

---

# 16. API Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/health` | GET | Service health |
| `/` | GET | Service information |
| `/docs` | GET | Swagger documentation |
| `/ai/chat` | POST | AI assistant |
| `/rag/ingest` | POST | Ingest documents |
| `/rag/search` | POST | Semantic document search |
| `/mcp/` | POST | MCP Streamable HTTP |

---

# 17. Complete Project Flow

```text
                         Project9 Messaging
                                │
                ┌───────────────┴───────────────┐
                │                               │
                ▼                               ▼
       Java Spring Boot                    Python FastAPI
           Service                            Service
                                                │
                          ┌─────────────────────┼─────────────────────┐
                          │                     │                     │
                          ▼                     ▼                     ▼
                       REST API              MCP Server            AI Layer
                                                │                     │
                                      ┌─────────┴─────────┐           │
                                      │                   │           │
                                      ▼                   ▼           ▼
                               getSystemInfo         calculate     Ollama
                                                                    │
                                                                    ▼
                                                                 Llama 3.2
                                                                    │
                                                                    ▼
                                                                   RAG
                                                                    │
                                                                    ▼
                                                                 ChromaDB
```

---

# 18. Development Checklist

```text
[✓] FastAPI service
[✓] Health API
[✓] REST APIs
[✓] MCP server
[✓] Streamable HTTP
[✓] MCP tool discovery
[✓] getSystemInfo tool
[✓] calculate tool
[✓] MCP client
[✓] Ollama integration
[✓] Llama 3.2
[✓] nomic-embed-text
[✓] RAG ingestion
[✓] ChromaDB vector search
[✓] RAG → LLM integration
[✓] LLM → MCP tool calling
[✓] AI orchestration
[✓] Basic UI
[ ] Additional production documentation
[ ] Expanded automated test coverage
[ ] Production deployment configuration
```

---

# 19. Troubleshooting

### FastAPI is not running

```bash
uvicorn app.main:app --reload --port 8000
```

### Check health

```bash
curl http://127.0.0.1:8000/health
```

### Check Ollama

```bash
curl http://127.0.0.1:11434/api/tags
```

### Check installed models

```bash
ollama list
```

### Check MCP tools

```bash
python -m app.ai.test_mcp_client
```

### MCP `/mcp` returns 307

Use:

```text
/mcp/
```

instead of:

```text
/mcp
```

The redirect is expected because the mounted Streamable HTTP endpoint uses the trailing slash.

---

# 20. Future Enhancements

The project can be extended with:

- PostgreSQL / Redis integration.
- Authentication and authorization.
- Production vector database.
- Multiple MCP servers.
- More MCP tools.
- Streaming LLM responses.
- Conversation memory.
- Document upload through UI.
- Source citations for RAG responses.
- Prometheus/Grafana observability.
- Docker/Kubernetes deployment.
- Helm deployment.
- CI/CD pipeline.
- Enterprise security controls.
- MCP tool authorization and auditing.

---

# 21. Summary

Project9 Messaging demonstrates an AI-enabled microservice architecture where:

**FastAPI** provides the application and AI API.

**MCP** provides a standardized interface for exposing executable tools.

**Ollama/Llama 3.2** provides local LLM capabilities.

**nomic-embed-text** generates document embeddings.

**ChromaDB** provides vector search for RAG.

**RAG** grounds Project9-specific answers in project documentation.

The final AI flow combines these components:

```text
User
 ↓
FastAPI
 ↓
AI Orchestrator
 ├── RAG → ChromaDB → Project documentation
 │
 ├── MCP → MCP Server → Tools
 │
 └── Ollama → Llama 3.2
                    ↓
               Final Answer
```

This provides a local, extensible foundation for an enterprise AI assistant with both knowledge retrieval and tool execution capabilities.
