# AI and Ollama

## Ollama

Ollama is used as the local LLM runtime.

The project uses:

llama3.2:3b

Ollama runs locally.

Default Ollama endpoint:

http://localhost:11434

## Chat Model

The chat model is configured using:

spring.ai.ollama.chat.options.model=llama3.2:3b

The chat model is responsible for generating AI responses and
deciding when available MCP tools should be used.

## Embedding Model

The project also uses an Ollama embedding model for RAG.

Embedding model:

nomic-embed-text

Configuration:

spring.ai.ollama.embedding.options.model=nomic-embed-text

## Difference

llama3.2:3b

Purpose:

Generate natural language responses.

nomic-embed-text

Purpose:

Convert documents and queries into numerical vectors for
semantic similarity search.

## AI Capabilities

The AI application can perform:

- General conversation
- Project knowledge retrieval using RAG
- MCP tool selection
- MCP tool execution through the MCP Client
