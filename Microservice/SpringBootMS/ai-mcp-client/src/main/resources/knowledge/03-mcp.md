# MCP Architecture

## MCP Server

The MCP Server is implemented inside spring-service.

The MCP Server exposes application functionality as MCP tools.

Current practice tools include:

- hello
- createUser

## MCP Client

The MCP Client is implemented inside ai-mcp-client.

The MCP Client connects to the MCP Server using SSE.

MCP Server endpoint:

http://localhost:8080/sse

AI MCP Client:

http://localhost:8081

## MCP Connection

The AI application contains configuration similar to:

spring.ai.mcp.client.enabled=true

spring.ai.mcp.client.type=SYNC

spring.ai.mcp.client.sse.connections.spring-service.url=http://localhost:8080

spring.ai.mcp.client.sse.connections.spring-service.sse-endpoint=/sse

## Tool Discovery

The MCP Client connects to the MCP Server.

The MCP Client discovers the available tools.

The discovered tools are provided to the AI application.

The LLM can decide whether a tool is required for a user request.

## Hello Tool

The hello tool is used as a simple MCP connectivity test.

## Create User Tool

The createUser tool demonstrates an AI-driven application action.

The tool ultimately calls the application's user business logic.

## Create User Flow

User request:

Create a user named Arpit.

Flow:

User
    |
    v
React
    |
    v
ai-mcp-client
    |
    v
Ollama
    |
    v
createUser MCP tool
    |
    v
MCP Server
    |
    v
UserMcpService
    |
    v
UserService
    |
    v
UserRepository
    |
    v
PostgreSQL
