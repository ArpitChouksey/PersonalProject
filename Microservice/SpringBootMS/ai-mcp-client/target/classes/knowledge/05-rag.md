# RAG Architecture

## RAG

RAG means Retrieval-Augmented Generation.

RAG allows the AI application to retrieve relevant project
information before generating an answer.

## RAG Components

The project uses:

- Project documentation
- Document loader
- Document chunks
- Ollama embedding model
- PostgreSQL
- PGVector
- Similarity search
- Ollama chat model

## RAG Ingestion Pipeline

Project documentation
        |
        v
Document Loader
        |
        v
Documents
        |
        v
Text Chunking
        |
        v
Document Chunks
        |
        v
nomic-embed-text
        |
        v
Embeddings
        |
        v
PGVector
        |
        v
PostgreSQL

## RAG Query Pipeline

User question
        |
        v
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

## Vector Database

The project uses PostgreSQL with the pgvector extension.

RAG database:

project9_rag

## Embedding Model

nomic-embed-text

The embedding model converts text into vectors.

The vectors are stored in PGVector.

## Why RAG Is Used

RAG allows the AI assistant to answer questions about
Project9-Messaging-specific information.

Examples:

- What is the project architecture?
- Which port does ai-mcp-client use?
- What does UserMcpService do?
- How does createUser work?
- How does the MCP connection work?
- How do I start the project?
