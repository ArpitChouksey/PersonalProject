# P9-MCP-CUSTOM-SERVER

**Project9-Messaging** — an enterprise-style learning platform that combines Spring Boot microservices, MCP (Model Context Protocol), AI/RAG, a local LLM, vector search, and event-driven messaging into one end-to-end system.

![Architecture](ProjectArch.png)

---

## What this repository contains

Three applications work together to turn a plain-English chat message into a real, persisted action in a Spring Boot microservice:

| App | Path | Port | Role |
|---|---|---|---|
| **spring-service** | `SpringBootMS/spring-service` | `8080` | Spring Boot CRUD microservice — business logic, PostgreSQL persistence, the **MCP Server**, and MCP tools (`hello`, `createUser`) |
| **ai-mcp-client** | `SpringBootMS/ai-mcp-client` | `8081` | Spring AI application — AI chat, Ollama (local LLM), RAG over PGVector, and the **MCP Client** that talks to spring-service over the real MCP protocol |
| **mcp-chat-ui** | `SpringBootMS/mcp-chat-ui` | `5173` (dev) / `80` (Docker/K8s) | React chat interface for talking to the assistant |

Request flow, end to end:

```text
User → React UI → AI MCP Client → RAG / Ollama → MCP Client → Spring Service → PostgreSQL / Kafka / Amazon MQ
```

---

## Repository structure

```text
P9-MCP-CUSTOM-SERVER/
├── ProjectArch.png                 # architecture diagram (shown above)
├── P9-MCP-CUSTOM-SERVER.docx        # Phase 1 build guide — MCP Server, MCP Client, RAG, UI, deployment, step by step
├── RealTimeMCP_SERVER.docx          # Phase 2 notes — real-time MCP work
│
├── KafkaServer/
│   └── docker-compose.yml           # local single-node Kafka broker (KRaft mode)
│
├── postgres-helm/                   # Helm chart for PostgreSQL (+ pgvector)
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/                   # deployment, pvc, secret, service, initdb configmap
│
└── SpringBootMS/
    ├── README.md                     # full operational reference — env vars, endpoints, Docker/Helm commands
    │
    ├── spring-service/                # MCP Server + REST API  (port 8080)
    │   ├── src/main/java/com/company/spring_service/
    │   │   ├── mcp/                     # MCP tools, config, DTOs (UserMcpService, McpToolConfig)
    │   │   ├── messaging/                # Kafka + Amazon MQ, provider-based
    │   │   ├── controller / service / repository / entity / dto / event
    │   │   └── SpringServiceApplication.java
    │   └── HELM/                        # springservicehelm, kafka, amazonmq charts
    │
    ├── ai-mcp-client/                  # MCP Client + AI chat + RAG  (port 8081)
    │   ├── src/main/java/com/company/ai/
    │   │   ├── controller/                # AIChatController, McpClientController, RagController
    │   │   ├── service/                    # AIChatService, McpClientService, ProjectKnowledgeService
    │   │   └── config/                      # CorsConfig, RagConfig
    │   ├── src/main/resources/knowledge/    # markdown knowledge base loaded into RAG
    │   └── HELM/                            # ai-mcp-client + Ollama charts
    │
    └── mcp-chat-ui/                    # React chat UI  (port 5173 local / 80 in Docker/K8s)
        ├── src/
        │   ├── App.jsx
        │   └── services/chatService.js
        └── HELM/mcp-chat-ui/
```

---

## Key capabilities

**MCP**
- MCP Server hosted inside `spring-service`, exposed over SSE (`/sse`, `/mcp/message`)
- MCP Client hosted inside `ai-mcp-client`, connected via `spring.ai.mcp.client.sse.connections.*`
- Current tools: `hello`, `createUser`
- The LLM calls real application functionality through the MCP protocol, not a local Java callback

**AI & RAG**
- Local inference via **Ollama** — `llama3.2` for chat, `nomic-embed-text` for embeddings
- **PostgreSQL + PGVector** for vector storage and similarity search
- `QuestionAnswerAdvisor` pipeline so the assistant can answer from the project's own knowledge base

**Messaging**
- **Kafka** for event streaming (local broker in `KafkaServer/docker-compose.yml`)
- **Amazon MQ** as an alternative, provider-selectable at runtime via `messaging.provider`

**Deployment**
- Docker images for all three apps
- Kubernetes + Helm charts for every component (`spring-service`, `ai-mcp-client`, `mcp-chat-ui`, `kafka`, `amazonmq`, `postgres-helm`, `Ollama`)
- Fully environment-variable driven configuration — the same build runs locally and in-cluster unchanged

---

## Documentation in this repository

| Document | What it's for |
|---|---|
| **`SpringBootMS/README.md`** | The operational reference — prerequisites, every environment variable, all curl/health checks, Docker build/run commands, and the full Kubernetes/Helm install order. Start here to actually run the project. |
| **`P9-MCP-CUSTOM-SERVER.docx`** | Phase 1 narrative build guide — how the MCP Server, MCP Client, RAG layer, and chat UI were built step by step, including the real errors hit along the way (log4j conflicts, package-name issues, `/mcp` 500s) and screenshots proving each stage worked. |
| **`RealTimeMCP_SERVER.docx`** | Phase 2 — real-time MCP work, building on Phase 1. |
| **`ProjectArch.png`** | The architecture diagram shown at the top of this file. |

---

## Quick start

Start infrastructure before application code, and start `spring-service` before `ai-mcp-client` (the MCP Client connects out to the MCP Server on startup):

```bash
# 1. PostgreSQL — project9_app and project9_rag databases, pgvector enabled
# (see postgres-helm/ for the Kubernetes version)

# 2. Kafka
cd KafkaServer
docker compose up -d

# 3. Ollama
ollama serve
ollama pull llama3.2:latest
ollama pull nomic-embed-text:latest

# 4. spring-service (MCP Server + REST API)
cd ../SpringBootMS/spring-service
./mvnw spring-boot:run

# 5. ai-mcp-client (MCP Client + AI chat + RAG)
cd ../ai-mcp-client
./mvnw spring-boot:run
curl -X POST http://localhost:8081/rag/load

# 6. mcp-chat-ui
cd ../mcp-chat-ui
npm ci
npm run dev
```

Open `http://localhost:5173` and try:

```text
Use the hello MCP tool and tell me its response.
Create a user named Arpit with email arpit@example.com using the appropriate MCP tool.
According to the Project9-Messaging knowledge base, explain the RAG query pipeline step by step.
```

For full environment-variable reference, health checks, Docker commands, and the Helm/Kubernetes install order, see **`SpringBootMS/README.md`**.

---

## Tech stack

Java 17 · Spring Boot · Spring AI · MCP (Model Context Protocol) · Ollama (`llama3.2`, `nomic-embed-text`) · PostgreSQL + PGVector · Kafka · Amazon MQ · React + Vite · Docker · Kubernetes · Helm
