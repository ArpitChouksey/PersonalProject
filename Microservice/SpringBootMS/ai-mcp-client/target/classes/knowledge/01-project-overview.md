# Project9-Messaging

## Project Overview

Project9-Messaging is an enterprise messaging and AI learning project.

The project currently contains:

- Spring Boot CRUD microservice
- MCP Server
- AI MCP Client
- Ollama
- React Chat UI
- PostgreSQL
- Kafka
- Amazon MQ

The project is being developed to understand how traditional
microservices, messaging systems, MCP, LLMs, RAG and AI agents
can work together.

## Main Applications

### spring-service

The Spring Boot microservice.

Responsibilities include:

- User CRUD operations
- Business logic
- PostgreSQL persistence
- MCP Server
- MCP tools
- Kafka integration
- Amazon MQ integration

Port:

8080

### ai-mcp-client

The AI application.

Responsibilities include:

- Spring AI
- Ollama
- MCP Client
- RAG
- PGVector
- AI chat processing

Port:

8081

### mcp-chat-ui

The React frontend application.

Responsibilities include:

- Chat user interface
- Sending user messages to the AI application
- Displaying AI responses
- Providing a chatbot interface

## High-Level Flow

React Chat UI sends a user message to ai-mcp-client.

ai-mcp-client communicates with Ollama.

If the request requires application knowledge,
the RAG system retrieves relevant project documentation.

If the request requires an application action,
the MCP Client can invoke an MCP tool.

The MCP Server is hosted inside spring-service.

The Spring service performs business logic and database operations.
