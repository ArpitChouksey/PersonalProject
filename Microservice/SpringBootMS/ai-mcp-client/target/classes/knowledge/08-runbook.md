# Project Runbook

## Prerequisites

The following services must be available:

- PostgreSQL
- Ollama
- spring-service
- ai-mcp-client
- mcp-chat-ui

## Start PostgreSQL

PostgreSQL is running in Kubernetes in the current development
environment.

The PostgreSQL database used by RAG is:

project9_rag

The PostgreSQL image must include pgvector.

## Start Ollama

Ollama must be running locally.

Verify:

ollama list

Required models:

llama3.2:3b
nomic-embed-text

## Start spring-service

Navigate to:

spring-service

Run:

mvn spring-boot:run

Expected port:

8080

## Verify MCP Server

Run:

curl -N http://localhost:8080/sse

The MCP Server should provide an SSE connection.

## Start ai-mcp-client

Navigate to:

ai-mcp-client

Run:

mvn spring-boot:run

Expected port:

8081

## Load RAG Knowledge

Run:

curl -X POST http://localhost:8081/rag/load

Expected response:

Project knowledge loaded successfully

## Test RAG

Example:

curl --get \
  --data-urlencode "message=Which port does ai-mcp-client run on?" \
  http://localhost:8081/ai/chat

Expected:

8081

## Test MCP

Example:

curl --get \
  --data-urlencode "message=Create a user named Arpit with email test@example.com" \
  http://localhost:8081/ai/chat

The AI should select the createUser MCP tool.

## Test General Chat

Example:

curl --get \
  --data-urlencode "message=Explain what Kubernetes is" \
  http://localhost:8081/ai/chat

The AI should answer without requiring an MCP tool.

## Test Combined RAG and MCP

Example:

Explain how user creation works in this project and then create
a user named Arpit.

The AI should use project knowledge to explain the architecture
and MCP to perform the createUser operation.
