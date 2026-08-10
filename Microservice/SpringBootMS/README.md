# Project9-Messaging

Project9-Messaging is a learning/enterprise-style platform that combines:

- Spring Boot CRUD microservice
- Spring AI
- MCP Server
- MCP Client
- Ollama / local LLM
- RAG
- PostgreSQL + PGVector
- Kafka
- Amazon MQ
- React Chat UI
- Docker
- Kubernetes / Helm

The main AI flow is:

```text
React Chat UI
     |
     v
AI MCP Client :8081
     |
     +--------------------+
     |                    |
     v                    v
   RAG                  Ollama
     |                 Llama model
     v
PostgreSQL
 + PGVector
     |
     |
     +------------------------------+
                                    |
                                    v
                             MCP Client
                                    |
                                    v
                         Spring Service :8080
                                    |
                           +--------+--------+
                           |                 |
                           v                 v
                      PostgreSQL        Messaging
                                       /        \
                                    Kafka      Amazon MQ
```

---

# 1. Project Structure

The project contains three main applications.

```text
SpringBootMS/
|
+-- spring-service/
|   +-- src/main/java/...
|   +-- src/main/resources/application.properties
|   +-- Dockerfile
|   +-- HELM/
|       +-- springservicehelm/
|       +-- kafka/
|       +-- amazonmq/
|
+-- ai-mcp-client/
|   +-- src/main/java/...
|   +-- src/main/resources/
|       +-- application.properties
|       +-- knowledge/
|   +-- Dockerfile
|   +-- HELM/
|       +-- ai-mcp-client/
|       +-- OLLAMA/
|
+-- mcp-chat-ui/
    +-- src/
    +-- Dockerfile
    +-- HELM/
```

---

# 2. What Each Application Does

## 2.1 spring-service

Path:

```text
spring-service/
```

Port:

```text
8080
```

Responsibilities:

- User CRUD
- PostgreSQL persistence
- Business logic
- MCP Server
- MCP tools
- Kafka producer/consumers
- Amazon MQ producer/consumer
- Python service client
- Actuator
- Prometheus metrics

Important classes:

```text
spring-service/src/main/java/com/company/spring_service/

controller/UserController.java
service/UserService.java
service/PythonClientService.java

mcp/service/UserMcpService.java
mcp/config/McpToolConfig.java

messaging/service/MessagingService.java
messaging/factory/MessagingProviderFactory.java
messaging/properties/MessagingProperties.java

messaging/kafka/...
messaging/amazonmq/...
```

---

## 2.2 ai-mcp-client

Path:

```text
ai-mcp-client/
```

Port:

```text
8081
```

Responsibilities:

- Spring AI
- Ollama chat model
- Ollama embedding model
- MCP Client
- MCP tool discovery
- MCP tool execution
- RAG
- PGVector
- AI chat API

Important classes:

```text
ai-mcp-client/src/main/java/com/company/ai/

service/AIChatService.java
service/McpClientService.java
service/ProjectKnowledgeService.java

config/RagConfig.java

controller/AIChatController.java
controller/McpClientController.java
controller/RagController.java
```

---

## 2.3 mcp-chat-ui

Path:

```text
mcp-chat-ui/
```

Local development port:

```text
5173
```

Docker/Helm application port:

```text
80
```

Responsibilities:

- React chat interface
- Sends questions to AI MCP Client
- Displays AI responses
- Provides simple MCP test prompts

---

# 3. Required Software

For local/bare-metal development install:

## Java

Java 17 is required.

Check:

```bash
java -version
```

Expected:

```text
17.x
```

---

## Maven

Maven is required for both Spring Boot applications.

Check:

```bash
mvn -version
```

Both projects also contain Maven wrappers where available.

You can use:

```bash
./mvnw
```

instead of system Maven.

---

## Node.js

Required for the React UI.

Recommended:

```text
Node.js 22+
```

Check:

```bash
node -v
npm -v
```

---

## PostgreSQL

PostgreSQL is required by:

- spring-service
- AI MCP Client / RAG

The RAG database must support the `pgvector` extension.

Check PostgreSQL:

```bash
psql --version
```

The project currently uses:

```text
PostgreSQL
pgvector
```

---

## Ollama

Ollama is required by the AI MCP Client.

Install Ollama and verify:

```bash
ollama --version
```

Start Ollama:

```bash
ollama serve
```

Keep this terminal running.

---

# 4. Ollama Setup

## 4.1 Pull the chat model

The project uses a Llama model.

For the current Kubernetes configuration:

```bash
ollama pull llama3.2:latest
```

## 4.2 Pull the embedding model

```bash
ollama pull nomic-embed-text:latest
```

Verify:

```bash
ollama list
```

You should see:

```text
llama3.2:latest
nomic-embed-text:latest
```

---

# 5. Test Ollama Before Starting the Applications

Check Ollama:

```bash
curl http://localhost:11434/
```

Expected:

```text
Ollama is running
```

Test the chat model:

```bash
curl --max-time 180 \
  http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "prompt": "Say hello in one short sentence.",
    "stream": false
  }'
```

Test the embedding model:

```bash
curl \
  http://localhost:11434/api/embed \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-embed-text:latest",
    "input": "Project9-Messaging"
  }'
```

Check loaded models/processes:

```bash
ollama ps
```

---

# 6. PostgreSQL Setup

Create the databases used by the applications.

For a simple local setup:

```sql
CREATE DATABASE project9_app;
CREATE DATABASE project9_rag;
```

Enable pgvector in the RAG database:

```bash
psql -U postgres -d project9_rag
```

Then:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

Verify:

```sql
SELECT extname FROM pg_extension WHERE extname = 'vector';
```

Expected:

```text
vector
```

## Important configuration note

The current local `ai-mcp-client` default is:

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://localhost:5432/project9_app}
```

The Helm configuration uses:

```text
project9_rag
```

Therefore, when running the AI MCP Client locally, explicitly set `DB_URL` if you want the RAG data in `project9_rag`:

```bash
export DB_URL=jdbc:postgresql://localhost:5432/project9_rag
export DB_USERNAME=postgres
export DB_PASSWORD=postgres
```

This is recommended for the current project.

---

# 7. Start spring-service Locally

Go to:

```bash
cd spring-service
```

Build:

```bash
./mvnw clean package -DskipTests
```

Start:

```bash
./mvnw spring-boot:run
```

Or:

```bash
java -jar target/spring-service-0.0.1-SNAPSHOT.jar
```

The service starts on:

```text
http://localhost:8080
```

---

# 8. spring-service Local Configuration

File:

```text
spring-service/src/main/resources/application.properties
```

The application supports environment-variable overrides.

Examples:

```bash
export SERVER_PORT=8080

export DB_URL=jdbc:postgresql://localhost:5432/project9_app
export DB_USERNAME=postgres
export DB_PASSWORD=postgres

export KAFKA_BOOTSTRAP_SERVERS=localhost:9092

export MESSAGING_PROVIDER=kafka
export MESSAGING_DESTINATION=user-events
```

Defaults are already present in `application.properties`.

For example:

```properties
server.port=${SERVER_PORT:8080}
```

means:

- use `SERVER_PORT` if provided
- otherwise use `8080`

---

# 9. Verify spring-service

Health:

```bash
curl http://localhost:8080/actuator/health
```

MCP SSE:

```bash
curl -N http://localhost:8080/sse
```

The MCP endpoint should establish an SSE connection.

Basic API:

```bash
curl http://localhost:8080/api/hello/Arpit
```

Create a user:

```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Arpit",
    "email": "arpit@example.com"
  }'
```

---

# 10. MCP Server

The MCP Server is implemented inside `spring-service`.

Important files:

```text
spring-service/src/main/java/com/company/spring_service/mcp/

service/UserMcpService.java
config/McpToolConfig.java
dto/CreateUserRequest.java
```

Current MCP tools:

```text
hello
createUser
```

## hello

Checks that the MCP application is working.

## createUser

Creates a user using the existing Spring Service business logic.

The MCP flow is:

```text
AI MCP Client
      |
      v
MCP Client
      |
      v
Spring Service MCP Server
      |
      v
UserMcpService
      |
      v
UserService
      |
      v
PostgreSQL
```

---

# 11. Start AI MCP Client Locally

Open another terminal.

Go to:

```bash
cd ai-mcp-client
```

Before starting, make sure Ollama and PostgreSQL are running.

For the current local setup:

```bash
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_CHAT_MODEL=llama3.2:latest
export OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest

export MCP_SERVER_URL=http://localhost:8080
export MCP_SSE_ENDPOINT=/sse

export DB_URL=jdbc:postgresql://localhost:5432/project9_rag
export DB_USERNAME=postgres
export DB_PASSWORD=postgres
```

Build:

```bash
./mvnw clean package -DskipTests
```

Start:

```bash
./mvnw spring-boot:run
```

The application starts on:

```text
http://localhost:8081
```

---

# 12. AI MCP Client Configuration

File:

```text
ai-mcp-client/src/main/resources/application.properties
```

Important settings:

```properties
spring.ai.ollama.base-url=${OLLAMA_BASE_URL:http://localhost:11434}

spring.ai.ollama.chat.options.model=${OLLAMA_CHAT_MODEL:llama3.2:3b}

spring.ai.ollama.embedding.options.model=${OLLAMA_EMBEDDING_MODEL:nomic-embed-text:latest}

spring.ai.mcp.client.sse.connections.spring-service.url=${MCP_SERVER_URL:http://localhost:8080}

spring.ai.mcp.client.sse.connections.spring-service.sse-endpoint=${MCP_SSE_ENDPOINT:/sse}
```

For the currently installed model, use:

```bash
export OLLAMA_CHAT_MODEL=llama3.2:latest
```

The application supports environment-variable overrides, so you do not need to edit the properties file for each environment.

---

# 13. Verify MCP Tools from AI MCP Client

Run:

```bash
curl -i http://localhost:8081/mcp/tools
```

Expected tools are similar to:

```json
[
  "ai_mcp_client_spring_service_createUser",
  "ai_mcp_client_spring_service_hello"
]
```

This verifies:

```text
AI MCP Client
      |
      v
MCP Server
      |
      v
Spring Service
      |
      v
MCP tools discovered
```

---

# 14. RAG Setup

Knowledge files are located at:

```text
ai-mcp-client/src/main/resources/knowledge/
```

Current files:

```text
01-project-overview.md
02-architecture.md
03-mcp.md
04-ai-ollama.md
05-rag.md
06-classes.md
07-configuration.md
08-runbook.md
```

The configuration is:

```properties
rag.knowledge-location=${RAG_KNOWLEDGE_LOCATION:classpath:/knowledge/*.md}
```

---

# 15. Load RAG Knowledge

After starting `ai-mcp-client`:

```bash
curl -i -X POST http://localhost:8081/rag/load
```

Expected response:

```text
Project knowledge loaded successfully. Chunks created: 8
```

The exact number can change if the knowledge files are changed.

---

# 16. Direct RAG Search Test

The project contains a diagnostic endpoint:

```text
GET /rag/search
```

Test:

```bash
curl --get \
  --data-urlencode "query=How does RAG work in Project9-Messaging?" \
  http://localhost:8081/rag/search
```

This directly tests:

```text
Question
   |
   v
Embedding
   |
   v
PGVector similarity search
   |
   v
Relevant document chunks
```

It does not depend on the LLM generating the final answer.

The returned metadata contains the source document and similarity information.

Example:

```json
"metadata": {
  "project": "Project9-Messaging",
  "source": "05-rag.md"
}
```

---

# 17. Test RAG Through the AI

Run:

```bash
curl --max-time 180 --get \
  --data-urlencode "message=According to the Project9-Messaging knowledge base, explain the RAG query pipeline step by step." \
  http://localhost:8081/ai/chat
```

Expected concepts:

```text
Question embedding
        |
        v
PGVector similarity search
        |
        v
Relevant document chunks
        |
        v
QuestionAnswerAdvisor
        |
        v
Ollama
        |
        v
Final answer
```

---

# 18. AI Chat API

Endpoint:

```text
GET /ai/chat
```

Example:

```bash
curl --max-time 180 --get \
  --data-urlencode "message=Hello" \
  http://localhost:8081/ai/chat
```

RAG example:

```bash
curl --max-time 180 --get \
  --data-urlencode "message=According to the project documentation, what port does ai-mcp-client use?" \
  http://localhost:8081/ai/chat
```

MCP example:

```bash
curl --max-time 180 --get \
  --data-urlencode "message=Use the hello MCP tool and tell me its response." \
  http://localhost:8081/ai/chat
```

Create-user example:

```bash
curl --max-time 180 --get \
  --data-urlencode "message=Create a user named Arpit with email arpit.mcp@example.com using the appropriate MCP tool." \
  http://localhost:8081/ai/chat
```

---

# 19. Start React UI Locally

Open another terminal.

Go to:

```bash
cd mcp-chat-ui
```

Install dependencies:

```bash
npm ci
```

Start development server:

```bash
npm run dev
```

Open:

```text
http://localhost:5173
```

The Vite configuration proxies:

```text
/api
```

to:

```text
http://localhost:8081
```

This means the browser does not need to directly call port 8081 during local UI development.

---

# 20. UI Test Prompts

## Basic AI

```text
Hello, introduce yourself as the Project9-Messaging AI assistant.
```

## RAG

```text
According to the Project9-Messaging knowledge base, explain the RAG query pipeline step by step.
```

## MCP discovery

```text
What MCP tools are currently available to you? List each tool and explain its purpose.
```

## MCP hello

```text
Use the hello MCP tool and tell me its exact response.
```

## MCP createUser

```text
Create a user named Arpit MCP Test with email arpit.mcp.test@example.com using the appropriate MCP tool.
```

## RAG + MCP

```text
According to the Project9-Messaging documentation, explain how user creation works in this project. Then create a user named Priya Sharma with email priya.mcp@example.com using the appropriate MCP tool.
```

---

# 21. Kafka

Kafka is the default messaging provider.

The configuration is:

```properties
messaging.provider=kafka
```

The Spring Service publishes to:

```text
user-events
```

The main configuration is:

```properties
spring.kafka.bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}

spring.kafka.consumer.group-id=${KAFKA_CONSUMER_GROUP_ID:user-service-group}

messaging.destination=${MESSAGING_DESTINATION:user-events}
```

## Kafka flow

```text
Spring Service
      |
      v
MessagingService
      |
      v
MessagingProviderFactory
      |
      v
KafkaProvider
      |
      v
KafkaProducer
      |
      v
Kafka topic: user-events
      |
      +--------------------+
      |                    |
      v                    v
KafkaConsumer        AuditConsumer
                           |
                           v
                      AuditService
                           |
                           v
                      PostgreSQL
```

---

# 22. Run Kafka Locally

For local development, Kafka can run independently from the Spring application.

The project also contains a Kubernetes Helm chart:

```text
spring-service/HELM/kafka/
```

The chart uses:

```text
apache/kafka
```

and configures Kafka in KRaft mode.

For a local Kafka installation, make sure Kafka is reachable at:

```text
localhost:9092
```

Then:

```bash
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export MESSAGING_PROVIDER=kafka
export MESSAGING_DESTINATION=user-events
```

Restart `spring-service` after changing environment variables.

---

# 23. Kafka Test API

The Spring Service contains a temporary Kafka test endpoint:

```text
POST /api/kafka/test
```

Run:

```bash
curl -X POST http://localhost:8080/api/kafka/test
```

Expected:

```text
Kafka Message Published Successfully
```

Check Spring Service logs for the producer and consumer messages.

---

# 24. Kafka Helm Deployment

Chart:

```text
spring-service/HELM/kafka/
```

Install:

```bash
helm install kafka ./spring-service/HELM/kafka
```

Check:

```bash
kubectl get pods
kubectl get svc
```

Expected service:

```text
kafka-service
```

Kafka is exposed internally on:

```text
kafka-service:9092
```

For Kubernetes Spring Service configuration, the Helm chart already uses:

```yaml
kafka:
  bootstrapServers: kafka-service:9092
```

---

# 25. Amazon MQ

Amazon MQ is the alternative messaging provider.

The application supports two providers:

```text
kafka
amazonmq
```

Provider selection happens through:

```properties
messaging.provider
```

For Amazon MQ:

```bash
export MESSAGING_PROVIDER=amazonmq
```

The application then uses:

```text
AmazonMQProvider
        |
        v
AmazonMQProducer
        |
        v
JmsTemplate
        |
        v
Amazon MQ broker
```

---

# 26. Amazon MQ Configuration

Required values:

```bash
export MESSAGING_PROVIDER=amazonmq

export AMAZONMQ_BROKER_URL="<Amazon-MQ-Broker-URL>"
export AMAZONMQ_USERNAME="<username>"
export AMAZONMQ_PASSWORD="<password>"
export AMAZONMQ_QUEUE=user-events
```

The Spring Service configuration contains:

```properties
amazonmq.enabled=${AMAZONMQ_ENABLED:false}

amazonmq.broker-url=${AMAZONMQ_BROKER_URL:}
amazonmq.username=${AMAZONMQ_USERNAME:}
amazonmq.password=${AMAZONMQ_PASSWORD:}

amazonmq.queue=${AMAZONMQ_QUEUE:user-events}
```

The Amazon MQ provider is activated based on:

```text
messaging.provider=amazonmq
```

---

# 27. Amazon MQ Test API

The Spring Service contains:

```text
POST /api/amazonmq/test
```

Run:

```bash
curl -X POST http://localhost:8080/api/amazonmq/test
```

Expected:

```text
Amazon MQ Message Published Successfully
```

Check the application logs and the Amazon MQ broker/queue.

---

# 28. Amazon MQ Helm Chart

Chart:

```text
spring-service/HELM/amazonmq/
```

This chart provides configuration objects for the Amazon MQ connection.

It does NOT deploy an Amazon MQ broker inside Kubernetes.

Amazon MQ is an AWS managed service.

Set the values in:

```text
spring-service/HELM/amazonmq/values.yaml
```

or provide them using your deployment process.

Do not commit real Amazon MQ credentials to Git.

---

# 29. Python Service

The Spring Service has an optional Python integration.

Endpoint:

```text
GET /api/call-python/{name}
```

Example:

```bash
curl http://localhost:8080/api/call-python/Arpit
```

The default Python service URL is:

```text
http://localhost:8000
```

Kubernetes Helm uses:

```text
http://python-service:8000
```

The Python service is not included in this project archive.

Therefore:

- Spring Service can start without calling it.
- `/api/call-python/{name}` requires the Python service to actually be running.

---

# 30. Docker - Spring Service

Path:

```text
spring-service/Dockerfile
```

Build:

```bash
cd spring-service

docker build -t spring-service:3.0 .
```

Run:

```bash
docker run --rm \
  -p 8080:8080 \
  -e DB_URL=jdbc:postgresql://host.docker.internal:5432/project9_app \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=postgres \
  -e KAFKA_BOOTSTRAP_SERVERS=host.docker.internal:9092 \
  -e MESSAGING_PROVIDER=kafka \
  spring-service:3.0
```

For Linux bare-metal Docker, `host.docker.internal` may need additional Docker host configuration. Use the actual reachable host/database/broker address when required.

---

# 31. Docker - AI MCP Client

Path:

```text
ai-mcp-client/Dockerfile
```

Build:

```bash
cd ai-mcp-client

docker build -t ai-mcp-client:1.0.0 .
```

For Docker running against local host services:

```bash
docker run --rm \
  -p 8081:8081 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e OLLAMA_CHAT_MODEL=llama3.2:latest \
  -e OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest \
  -e MCP_SERVER_URL=http://host.docker.internal:8080 \
  -e MCP_SSE_ENDPOINT=/sse \
  -e DB_URL=jdbc:postgresql://host.docker.internal:5432/project9_rag \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=postgres \
  ai-mcp-client:1.0.0
```

---

# 32. Docker - React UI

Path:

```text
mcp-chat-ui/Dockerfile
```

Build:

```bash
cd mcp-chat-ui

docker build -t mcp-chat-ui:1.0.0 .
```

Run:

```bash
docker run --rm \
  -p 5173:80 \
  -e AI_BACKEND_HOST=host.docker.internal \
  -e AI_BACKEND_PORT=8081 \
  mcp-chat-ui:1.0.0
```

Open:

```text
http://localhost:5173
```

The UI uses Nginx as the runtime web server.

---

# 33. Ollama Docker / Kubernetes

Ollama Helm chart:

```text
ai-mcp-client/HELM/OLLAMA/helmollama/
```

The chart:

- Starts Ollama
- Creates persistent storage
- Automatically pulls the chat model
- Automatically pulls the embedding model
- Exposes port 11434

Configured models:

```yaml
models:
  chat: "llama3.2:latest"
  embedding: "nomic-embed-text:latest"
```

---

# 34. Ollama Helm Installation

From:

```text
ai-mcp-client/HELM/OLLAMA/
```

run:

```bash
helm install ollama ./helmollama
```

Check:

```bash
kubectl get pods
kubectl get svc
```

Expected service:

```text
ollama-service
```

Check Ollama:

```bash
kubectl exec -it deployment/ollama -- ollama list
```

Expected models:

```text
llama3.2:latest
nomic-embed-text:latest
```

Check loaded models:

```bash
kubectl exec -it deployment/ollama -- ollama ps
```

---

# 35. Important Ollama Kubernetes Note

The first model download can take time because Llama is a large model.

The Helm chart automatically runs:

```bash
ollama pull llama3.2:latest
ollama pull nomic-embed-text:latest
```

The Ollama data is persisted at:

```text
/root/.ollama
```

through the PVC.

If model downloads fail because the Kubernetes cluster cannot resolve/access Ollama's registry, verify cluster DNS and internet connectivity.

---

# 36. Helm - Spring Service

Chart:

```text
spring-service/HELM/springservicehelm/
```

The chart expects:

```text
PostgreSQL
Kafka
optional Python service
optional Amazon MQ
```

Install:

```bash
helm install spring-service ./spring-service/HELM/springservicehelm
```

Check:

```bash
kubectl get pods
kubectl get svc
```

Spring Service port:

```text
8080
```

Kubernetes service:

```text
spring-service
```

---

# 37. Helm - AI MCP Client

Chart:

```text
ai-mcp-client/HELM/ai-mcp-client/
```

Install:

```bash
helm install ai-mcp-client ./ai-mcp-client/HELM/ai-mcp-client
```

The Kubernetes configuration uses:

```text
Ollama:
http://ollama-service:11434

MCP Server:
http://spring-service:8080

PostgreSQL:
postgres-service:5432
```

AI MCP Client port:

```text
8081
```

---

# 38. Helm - React UI

Chart:

```text
mcp-chat-ui/HELM/mcp-chat-ui/
```

Install:

```bash
helm install mcp-chat-ui ./mcp-chat-ui/HELM/mcp-chat-ui
```

The UI communicates internally with:

```text
ai-mcp-client:8081
```

Service port:

```text
80
```

---

# 39. Recommended Kubernetes Installation Order

Install infrastructure first.

```text
1. PostgreSQL + PGVector
2. Kafka
3. Ollama
4. Spring Service
5. AI MCP Client
6. React UI
```

Commands:

```bash
helm install kafka ./spring-service/HELM/kafka

helm install ollama ./ai-mcp-client/HELM/OLLAMA/helmollama

helm install spring-service ./spring-service/HELM/springservicehelm

helm install ai-mcp-client ./ai-mcp-client/HELM/ai-mcp-client

helm install mcp-chat-ui ./mcp-chat-ui/HELM/mcp-chat-ui
```

Verify:

```bash
kubectl get pods
kubectl get svc
```

---

# 40. Kubernetes Service Names

The current Helm configuration uses these service names:

```text
spring-service
ai-mcp-client
ollama-service
kafka-service
postgres-service
mcp-chat-ui
```

Important internal URLs:

```text
Spring Service:
http://spring-service:8080

MCP:
http://spring-service:8080/sse

Ollama:
http://ollama-service:11434

Kafka:
kafka-service:9092

AI MCP Client:
http://ai-mcp-client:8081
```

---

# 41. Local vs Kubernetes URLs

## Local

```text
React UI:
http://localhost:5173

AI MCP Client:
http://localhost:8081

Spring Service:
http://localhost:8080

Ollama:
http://localhost:11434

PostgreSQL:
localhost:5432

Kafka:
localhost:9092
```

## Kubernetes

```text
React UI:
mcp-chat-ui:80

AI MCP Client:
ai-mcp-client:8081

Spring Service:
spring-service:8080

Ollama:
ollama-service:11434

PostgreSQL:
postgres-service:5432

Kafka:
kafka-service:9092
```

---

# 42. Health Checks

## Spring Service

```bash
curl http://localhost:8080/actuator/health
```

## AI MCP Client

The main application endpoint:

```bash
curl http://localhost:8081/mcp/tools
```

## Ollama

```bash
curl http://localhost:11434/
```

## MCP Server

```bash
curl -N http://localhost:8080/sse
```

---

# 43. Complete Local Startup

For a normal local/bare-metal setup, start services in this order.

### Terminal 1 - PostgreSQL

Start PostgreSQL and make sure `project9_app` and `project9_rag` exist.

### Terminal 2 - Ollama

```bash
ollama serve
```

Verify:

```bash
ollama list
```

### Terminal 3 - Kafka

Start Kafka and make sure:

```text
localhost:9092
```

is reachable.

### Terminal 4 - Spring Service

```bash
cd spring-service

export DB_URL=jdbc:postgresql://localhost:5432/project9_app
export DB_USERNAME=postgres
export DB_PASSWORD=postgres
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export MESSAGING_PROVIDER=kafka

./mvnw spring-boot:run
```

### Terminal 5 - AI MCP Client

```bash
cd ai-mcp-client

export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_CHAT_MODEL=llama3.2:latest
export OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest

export MCP_SERVER_URL=http://localhost:8080
export MCP_SSE_ENDPOINT=/sse

export DB_URL=jdbc:postgresql://localhost:5432/project9_rag
export DB_USERNAME=postgres
export DB_PASSWORD=postgres

./mvnw spring-boot:run
```

### Terminal 6 - Load RAG

```bash
curl -X POST http://localhost:8081/rag/load
```

### Terminal 7 - React UI

```bash
cd mcp-chat-ui

npm ci
npm run dev
```

Open:

```text
http://localhost:5173
```

---

# 44. Complete Verification

## Step 1 - Spring

```bash
curl http://localhost:8080/actuator/health
```

## Step 2 - MCP

```bash
curl -N http://localhost:8080/sse
```

## Step 3 - Ollama

```bash
curl http://localhost:11434/
```

## Step 4 - Models

```bash
ollama list
```

## Step 5 - MCP tools

```bash
curl http://localhost:8081/mcp/tools
```

## Step 6 - Load RAG

```bash
curl -X POST http://localhost:8081/rag/load
```

## Step 7 - Direct RAG

```bash
curl --get \
  --data-urlencode "query=How does RAG work in Project9-Messaging?" \
  http://localhost:8081/rag/search
```

## Step 8 - AI + RAG

```bash
curl --max-time 180 --get \
  --data-urlencode "message=According to the Project9-Messaging knowledge base, explain the RAG query pipeline." \
  http://localhost:8081/ai/chat
```

## Step 9 - MCP hello

```bash
curl --max-time 180 --get \
  --data-urlencode "message=Use the hello MCP tool and tell me its response." \
  http://localhost:8081/ai/chat
```

## Step 10 - MCP createUser

```bash
curl --max-time 180 --get \
  --data-urlencode "message=Create a user named Arpit Final Test with email arpit.final.test@example.com using the appropriate MCP tool." \
  http://localhost:8081/ai/chat
```

---

# 45. Troubleshooting

## Ollama does not respond

Check:

```bash
ollama ps
ollama list
curl http://localhost:11434/
```

Start it if required:

```bash
ollama serve
```

Pull models:

```bash
ollama pull llama3.2:latest
ollama pull nomic-embed-text:latest
```

---

## AI MCP Client cannot connect to Ollama

Check:

```bash
echo $OLLAMA_BASE_URL
echo $OLLAMA_CHAT_MODEL
echo $OLLAMA_EMBEDDING_MODEL
```

Local expected:

```text
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_CHAT_MODEL=llama3.2:latest
OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest
```

---

## MCP tools are missing

Check Spring Service:

```bash
curl -N http://localhost:8080/sse
```

Then:

```bash
curl http://localhost:8081/mcp/tools
```

Expected tools include:

```text
hello
createUser
```

Also check AI MCP Client logs for the MCP server capabilities.

---

## RAG returns no useful information

First load the knowledge:

```bash
curl -X POST http://localhost:8081/rag/load
```

Then directly test:

```bash
curl --get \
  --data-urlencode "query=How does RAG work in Project9-Messaging?" \
  http://localhost:8081/rag/search
```

Check that returned metadata contains a source such as:

```text
05-rag.md
```

Also verify PGVector exists:

```sql
SELECT extname
FROM pg_extension
WHERE extname = 'vector';
```

---

## RAG database connection fails

Check:

```bash
echo $DB_URL
echo $DB_USERNAME
```

For the recommended local RAG setup:

```text
jdbc:postgresql://localhost:5432/project9_rag
```

---

## Kafka connection fails

Check:

```bash
echo $KAFKA_BOOTSTRAP_SERVERS
```

Local:

```text
localhost:9092
```

Kubernetes:

```text
kafka-service:9092
```

Also verify Kafka is running.

---

## Amazon MQ connection fails

Verify:

```bash
echo $MESSAGING_PROVIDER
echo $AMAZONMQ_BROKER_URL
echo $AMAZONMQ_USERNAME
echo $AMAZONMQ_QUEUE
```

Provider must be:

```text
amazonmq
```

Do not use Amazon MQ settings when:

```text
MESSAGING_PROVIDER=kafka
```

---

## UI returns 504 / request times out

The local Llama model may take significant time to load and generate responses, especially on CPU.

Check:

```bash
ollama ps
```

The first request after model loading can be slower.

Test Ollama directly:

```bash
curl --max-time 180 \
  http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:latest",
    "prompt": "Say hello",
    "stream": false
  }'
```

If this works, test:

```bash
curl --max-time 180 \
  --get \
  --data-urlencode "message=Hello" \
  http://localhost:8081/ai/chat
```

---

# 46. Important Configuration Principle

The applications use Spring's environment-variable placeholder pattern.

Example:

```properties
server.port=${SERVER_PORT:8080}
```

Meaning:

```text
SERVER_PORT exists
       |
       +----> use it
       |
       no
       |
       +----> use 8080
```

This allows the same application to work locally and in Kubernetes.

Local:

```text
localhost
```

Kubernetes:

```text
Kubernetes service names
```

The Java code does not need to change.

---

# 47. Important Security Notes

Do not commit:

```text
DB_PASSWORD
AMAZONMQ_USERNAME
AMAZONMQ_PASSWORD
```

with real production credentials.

For Kubernetes, use Kubernetes Secrets.

For production, prefer:

- AWS Secrets Manager
- External Secrets
- Kubernetes Secrets with proper secret management
- IAM where supported

The current Helm files contain development/default credentials for learning purposes.

---

# 48. Current Project End-to-End Architecture

```text
                         +----------------+
                         |   React UI     |
                         |     :5173      |
                         +-------+--------+
                                 |
                                 v
                         +----------------+
                         | AI MCP Client  |
                         |     :8081      |
                         +---+--------+---+
                             |        |
                    RAG      |        | MCP
                             |        |
                             v        v
                       +---------+  +----------------+
                       | PGVector|  | Spring Service |
                       |Postgres |  |     :8080      |
                       +---------+  +---+---------+--+
                                         |         |
                                         |         |
                                         v         v
                                    PostgreSQL   Messaging
                                                 |
                                      +----------+----------+
                                      |                     |
                                      v                     v
                                    Kafka               Amazon MQ
```

Ollama is used by the AI MCP Client for:

```text
Chat generation
Embedding generation
```

---

# 49. Final Checklist

Before considering the project ready:

```text
[ ] Java 17 installed
[ ] Maven available
[ ] Node.js/npm available
[ ] PostgreSQL running
[ ] pgvector enabled
[ ] Ollama running
[ ] llama3.2 model installed
[ ] nomic-embed-text installed
[ ] Kafka running if Kafka provider is used
[ ] Amazon MQ configured if Amazon MQ provider is used

[ ] spring-service running on 8080
[ ] MCP SSE working
[ ] MCP hello tool working
[ ] MCP createUser tool working

[ ] ai-mcp-client running on 8081
[ ] MCP tools discovered
[ ] RAG knowledge loaded
[ ] Direct RAG search working
[ ] AI + RAG working
[ ] AI + MCP working
[ ] React UI running
[ ] UI + RAG working
[ ] UI + MCP working
[ ] Combined RAG + MCP test working
```

---

# 50. Recommended First Run

If you are running the project for the first time locally, use this sequence:

```bash
# 1. Start PostgreSQL

# 2. Start Ollama
ollama serve

# 3. Verify models
ollama list

# 4. Start Kafka

# 5. Start Spring Service
cd spring-service
./mvnw spring-boot:run

# 6. Start AI MCP Client
cd ../ai-mcp-client

export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_CHAT_MODEL=llama3.2:latest
export OLLAMA_EMBEDDING_MODEL=nomic-embed-text:latest
export MCP_SERVER_URL=http://localhost:8080
export MCP_SSE_ENDPOINT=/sse
export DB_URL=jdbc:postgresql://localhost:5432/project9_rag
export DB_USERNAME=postgres
export DB_PASSWORD=postgres

./mvnw spring-boot:run

# 7. Load RAG
curl -X POST http://localhost:8081/rag/load

# 8. Start UI
cd ../mcp-chat-ui
npm ci
npm run dev

# 9. Open browser
http://localhost:5173
```

Then test:

```text
Use the hello MCP tool and tell me its response.
```

and:

```text
According to the Project9-Messaging knowledge base, explain the RAG query pipeline step by step.
```

Finally:

```text
According to the Project9-Messaging documentation, explain how user creation works and then create a user named Arpit Final Test with email arpit.final.test@example.com using the appropriate MCP tool.
```

---

# 51. Project Status

The current implementation has been tested for:

- Spring Boot service
- MCP Server
- MCP tool discovery
- MCP `hello`
- MCP `createUser`
- Ollama
- Llama model
- Embedding model
- PostgreSQL
- PGVector
- RAG ingestion
- RAG similarity search
- QuestionAnswerAdvisor
- AI chat
- React UI
- Kafka provider
- Amazon MQ provider configuration
- Docker
- Helm/Kubernetes deployment configuration

The project is designed so that application configuration can be changed through environment variables rather than changing Java source code.
