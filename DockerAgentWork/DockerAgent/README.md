 Docker Agent

A basic Agentic AI project that combines **FastAPI, Ollama/Llama 3.2, and Docker tools** to allow users to interact with Docker using natural-language requests.

The project demonstrates how an LLM can understand a user's request, select an appropriate operation, and execute that operation through controlled Python tools.

---

## Project Overview

The main idea of this project is:

```text
User
  |
  | Natural Language
  v
FastAPI
  |
  v
LLM / Ollama
  |
  | Understand Intent
  v
Tool Selection
  |
  v
Docker / Linux Tool
  |
  v
System Result
  |
  v
LLM / API Response
  |
  v
User

The project can interact with local Docker and system resources through Python-based tools.

Features

The project contains tools for operations such as:

Docker
List Docker containers
List Docker images
Inspect containers
Read container logs
Container diagnostics
Docker Compose operations
Docker image related operations
Dockerfile generation
Linux / System
Process information
Disk usage
Memory usage
Other basic system operations
AI
Natural-language interaction
Local LLM using Ollama
LLM-based intent understanding
Tool selection
Dockerfile generation from natural-language requirements
Technology Stack
Technology	Purpose
Python	Application and tool implementation
FastAPI	REST API
Ollama	Local LLM runtime
Llama 3.2	Local language model
Docker	Container operations
React	Frontend
Vite	Frontend development/build
Nginx	Frontend container serving
Project Structure
DockerAgent/
│
├── docker-agent/
│   │
│   ├── app/
│   │   ├── __init__.py
│   │   ├── agent.py
│   │   ├── container_diagnostics.py
│   │   ├── compose_tools.py
│   │   ├── dependency_tools.py
│   │   ├── docker_tools.py
│   │   ├── dockerfile_validator.py
│   │   ├── executor.py
│   │   ├── image_tools.py
│   │   ├── linux_tools.py
│   │   ├── llm_agent.py
│   │   ├── registry_tools.py
│   │   ├── safety.py
│   │   ├── security_tools.py
│   │   └── tool_registry.py
│   │
│   ├── api/
│   │   └── server.py
│   │
│   ├── tests/
│   │   └── test_docker_tools.py
│   │
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py
│
└── frontend/
    ├── src/
    │   ├── App.jsx
    │   ├── App.css
    │   ├── api.js
    │   ├── index.css
    │   └── main.jsx
    │
    ├── Dockerfile
    ├── nginx.conf
    ├── package.json
    └── index.html
Backend Architecture

The backend contains three major layers.

                    ┌─────────────────┐
                    │      User       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    FastAPI      │
                    │   API Server    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    LLM Agent    │
                    │  Ollama/Llama   │
                    └────────┬────────┘
                             │
                       Tool Selection
                             │
             ┌───────────────┼───────────────┐
             │               │               │
             ▼               ▼               ▼
       Docker Tools     Linux Tools     Other Tools
             │               │               │
             └───────────────┼───────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Local System /  │
                    │     Docker      │
                    └─────────────────┘
LLM

The project uses a local Llama model through Ollama.

Default configuration:

Model: llama3.2
Ollama: http://localhost:11434

Check Ollama:

ollama --version

Check installed models:

ollama list

If required:

ollama pull llama3.2
Backend Setup

Go to the backend directory:

cd docker-agent

Create a virtual environment:

python3 -m venv .venv

Activate it:

source .venv/bin/activate

Install dependencies:

pip install -r requirements.txt
Start Ollama

Run:

ollama run llama3.2

Keep Ollama running.

Start Backend

From the docker-agent directory:

python -m uvicorn api.server:app --reload --port 8000

Backend:

http://127.0.0.1:8000
Verify Backend

Check the available tools:

curl http://127.0.0.1:8000/tools

Example:

{
  "status": "SUCCESS",
  "tools": [
    "docker_ps",
    "docker_images",
    "docker_container_inspect",
    "docker_container_logs",
    "process_list",
    "disk_usage",
    "memory_usage"
  ]
}
Testing the Agent
1. List Containers
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show me all containers"}'
2. List Running Containers
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"What containers are currently running?"}'
3. List Docker Images
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show all Docker images"}'
4. Container Logs
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show logs for docker-agent-backend"}'
5. Container Information
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Give me information about docker-agent-backend"}'
6. Memory Usage
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show memory usage"}'
7. Disk Usage
curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show disk usage"}'
Dockerfile Generation

The project can also use the LLM to generate Dockerfiles from natural-language requirements.

Example:

Create a production Java Dockerfile using
eclipse-temurin:21-jdk.

Use /app as the working directory.
Copy app.jar into /app.
Expose port 8080.
Start it using java -jar app.jar.

The LLM can generate:

FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY app.jar /app

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]

The generated Dockerfile can be saved locally for the user.

Frontend

The project also contains a React frontend.

Go to:

cd frontend

Install dependencies:

npm install

Start development server:

npm run dev

The frontend can then communicate with the FastAPI backend.

Docker Backend

The backend contains a Dockerfile.

Build the backend image:

docker build -t docker-agent-backend:latest ./docker-agent

Run the backend:

docker run -d \
  --name docker-agent-backend \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e OLLAMA_MODEL=llama3.2 \
  docker-agent-backend:latest

Check logs:

docker logs docker-agent-backend
Docker Frontend

Build:

docker build -t docker-agent-frontend:latest ./frontend

Run:

docker run -d \
  --name docker-agent-frontend \
  -p 5173:80 \
  docker-agent-frontend:latest

Frontend:

http://127.0.0.1:5173
Check Running Containers
docker ps

Example:

CONTAINER ID   IMAGE                       STATUS
xxxxxx         docker-agent-backend       Up
xxxxxx         docker-agent-frontend      Up
Check Docker Images
docker images
Backend Health Check
curl http://127.0.0.1:8000/tools

If the API responds with the available tools, the backend is running correctly.

Agent Request Flow

For a request such as:

Show all Docker images

the flow is:

User
  |
  ▼
FastAPI
  |
  ▼
LLM
  |
  ▼
Understand User Intent
  |
  ▼
Select docker_images Tool
  |
  ▼
Docker CLI
  |
  ▼
Docker Image Information
  |
  ▼
Agent Response

For:

Show running containers

the flow becomes:

User
  |
  ▼
LLM
  |
  ▼
docker_ps Tool
  |
  ▼
docker ps
  |
  ▼
Container Information
Important Concept

The LLM does not directly access Docker.

The application exposes controlled tools to the LLM.

LLM
 |
 | Select Tool
 ▼
Python Tool
 |
 | Execute command
 ▼
Docker / Linux

This separation allows the application to control what operations the agent is allowed to perform.

Tool Registry

The project contains a tool registry that provides a central place for the available tools.

Conceptually:

Tool Registry
     |
     ├── docker_ps
     ├── docker_images
     ├── docker_container_inspect
     ├── docker_container_logs
     ├── process_list
     ├── disk_usage
     └── memory_usage

The agent can use the registered tools based on the user's request.

Error Handling

If a tool fails, the API returns an error response instead of silently pretending that the operation succeeded.

Example:

{
  "status": "ERROR",
  "message": "Tool execution failed"
}
Testing Docker Directly

Before testing the agent, Docker can be tested independently.

List containers:

docker ps -a

List images:

docker images

Check a container:

docker inspect <container-name>

Check logs:

docker logs <container-name>
Complete Local Startup
Terminal 1 — Ollama
ollama run llama3.2
Terminal 2 — Backend
cd docker-agent
source .venv/bin/activate
python -m uvicorn api.server:app --reload --port 8000
Terminal 3 — Test
curl http://127.0.0.1:8000/tools

Then:

curl -X POST http://127.0.0.1:8000/agent/chat \
-H "Content-Type: application/json" \
-d '{"message":"Show me all containers"}'
Interview Summary

This project demonstrates the basic architecture of an Agentic AI system.

The important concepts are:

User sends a natural-language request.
FastAPI receives the request.
The LLM understands the request.
The agent determines the appropriate tool.
The Python tool performs the actual operation.
Docker or the local system provides the result.
The result is returned to the user.

In short:

Natural Language
       ↓
      LLM
       ↓
  Tool Selection
       ↓
Python Tool
       ↓
Docker / System
       ↓
    Result

The project can be extended later with additional tools, approval workflows, monitoring, automated remediation, and production-grade security controls.
