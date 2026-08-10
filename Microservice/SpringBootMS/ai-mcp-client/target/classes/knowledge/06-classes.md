# Important Classes

## spring-service

### UserController

Handles normal REST user CRUD requests.

### UserService

Contains user-related business logic.

### UserRepository

Provides persistence access for users.

### UserMcpService

Exposes application functionality as MCP tools.

Current MCP functionality includes:

- hello
- createUser

### McpToolConfig

Configures MCP tool registration.

## AI MCP Client

### AIChatService

Handles AI chat requests.

It provides:

- User message to the ChatClient
- RAG advisor
- MCP tool callbacks
- AI response generation

### McpClientService

Works with tools discovered through the MCP Client.

### RagController

Exposes the RAG ingestion endpoint.

Endpoint:

POST /rag/load

### ProjectKnowledgeService

Loads project knowledge into the VectorStore.

The service is responsible for:

- Reading project knowledge
- Creating Documents
- Splitting Documents into chunks
- Storing chunks in PGVector

### RagConfig

Creates the QuestionAnswerAdvisor.

The QuestionAnswerAdvisor connects the ChatClient to the VectorStore
for retrieval-augmented generation.

## React

### mcp-chat-ui

Provides the frontend chatbot interface.

It communicates with ai-mcp-client.
