# Configuration

## spring-service

Application port:

8080

MCP SSE endpoint:

/sse

MCP message endpoint:

/mcp/message

## ai-mcp-client

Application port:

8081

Ollama:

http://localhost:11434

Chat model:

llama3.2:3b

Embedding model:

nomic-embed-text

MCP Server:

http://localhost:8080

MCP SSE endpoint:

/sse

## PostgreSQL

PostgreSQL is used by the project for application data.

The RAG system uses a PostgreSQL database with pgvector.

RAG database:

project9_rag

## Database Environment Variables

The AI application uses:

DB_URL
DB_USERNAME
DB_PASSWORD

Configuration:

spring.datasource.url=${DB_URL}

spring.datasource.username=${DB_USERNAME}

spring.datasource.password=${DB_PASSWORD}

## Example RAG Database URL

jdbc:postgresql://localhost:5432/project9_rag

## Ollama

Ollama default endpoint:

http://localhost:11434
