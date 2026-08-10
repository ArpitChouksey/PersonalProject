# Project Architecture

## Applications

The system has three primary application layers.

### Frontend

mcp-chat-ui

Technology:

- React

Purpose:

Provides the chatbot interface.

### AI Application

ai-mcp-client

Technology:

- Java
- Spring Boot
- Spring AI
- Ollama
- MCP Client
- PGVector

Port:

8081

Purpose:

Acts as the AI orchestration layer.

### Business Application

spring-service

Technology:

- Java
- Spring Boot
- PostgreSQL
- MCP Server
- Kafka
- Amazon MQ

Port:

8080

Purpose:

Provides application business functionality and exposes selected
operations through MCP tools.

## Request Flow

Normal AI request:

React
    |
    v
ai-mcp-client
    |
    v
Ollama
    |
    v
AI response

RAG request:

React
    |
    v
ai-mcp-client
    |
    v
PGVector
    |
    v
Relevant project documents
    |
    v
Ollama
    |
    v
AI response

MCP request:

React
    |
    v
ai-mcp-client
    |
    v
Ollama
    |
    v
MCP Client
    |
    | MCP over SSE
    v
spring-service
    |
    v
MCP Server
    |
    v
MCP Tool
    |
    v
Business Service
    |
    v
PostgreSQL
