import httpx
from typing import Any

from app.ai.mcp_client import MCPClientService


class AIService:

    def __init__(
        self,
        ollama_url: str = "http://127.0.0.1:11434",
        model: str = "llama3.2",
        rag_url: str = "http://127.0.0.1:8000",
    ):
        self.ollama_url = ollama_url.rstrip("/")
        self.model = model
        self.rag_url = rag_url.rstrip("/")

        self.mcp_client = MCPClientService()

    # ---------------------------------------------------------
    # RAG
    # ---------------------------------------------------------

    async def search_rag(
        self,
        query: str,
        top_k: int = 3,
    ) -> str:

        payload = {
            "query": query,
            "top_k": top_k,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:

            response = await client.post(
                f"{self.rag_url}/rag/search",
                json=payload,
            )

            response.raise_for_status()

            data = response.json()

        documents = data.get("documents", [])

        if not documents:
            return ""

        # Chroma returns:
        # documents = [["chunk1", "chunk2"]]

        if isinstance(documents[0], list):
            documents = documents[0]

        return "\n\n--- DOCUMENT CHUNK ---\n\n".join(
            str(document)
            for document in documents
        )

    # ---------------------------------------------------------
    # MCP TOOL DISCOVERY
    # ---------------------------------------------------------

    async def get_mcp_tools(self) -> list[dict[str, Any]]:

        tools = await self.mcp_client.list_tools()

        ollama_tools = []

        for tool in tools:

            ollama_tools.append(
                {
                    "type": "function",
                    "function": {
                        "name": tool["name"],
                        "description": tool["description"],
                        "parameters": tool["input_schema"],
                    },
                }
            )

        return ollama_tools

    # ---------------------------------------------------------
    # OLLAMA
    # ---------------------------------------------------------

    async def call_ollama(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
        }

        if tools:
            payload["tools"] = tools

        async with httpx.AsyncClient(
            timeout=120.0
        ) as client:

            response = await client.post(
                f"{self.ollama_url}/api/chat",
                json=payload,
            )

            response.raise_for_status()

            return response.json()

    # ---------------------------------------------------------
    # MAIN AI FLOW
    # ---------------------------------------------------------

    async def chat(
        self,
        user_message: str,
    ) -> str:

        # -----------------------------------------------------
        # STEP 1
        # Retrieve relevant project documentation
        # -----------------------------------------------------

        rag_context = await self.search_rag(
            user_message,
            top_k=3,
        )

        # -----------------------------------------------------
        # STEP 2
        # Discover MCP tools
        # -----------------------------------------------------

        mcp_tools = await self.get_mcp_tools()

        # -----------------------------------------------------
        # STEP 3
        # Build system prompt
        # -----------------------------------------------------

        system_prompt = """
You are the Project9 Messaging AI Assistant.

You have access to:

1. Project9 documentation through RAG.
2. MCP tools that you may use when required.

IMPORTANT RULES:

- Use the retrieved Project9 documentation for Project9-specific questions.
- Do not invent information about Project9.
- If the documentation does not contain the answer, clearly say that
  the information was not found in the Project9 documentation.
- You may answer general questions using your own knowledge.
- Use MCP tools when the user's request explicitly requires a tool
  or when a tool is clearly appropriate.
- Do not manually calculate a value when the user explicitly requires
  the calculate MCP tool.
- After receiving a tool result, use that result to formulate the
  final answer.
"""

        if rag_context:

            system_prompt += f"""

RETRIEVED PROJECT9 DOCUMENTATION:

-------------------------------
{rag_context}
-------------------------------

Use this documentation when answering Project9-specific questions.
"""

        else:

            system_prompt += """

No relevant Project9 documentation was found for this request.
Do not invent Project9-specific information.
"""

        messages: list[dict[str, Any]] = [
            {
                "role": "system",
                "content": system_prompt,
            },
            {
                "role": "user",
                "content": user_message,
            },
        ]

        # -----------------------------------------------------
        # STEP 4
        # First LLM call
        # -----------------------------------------------------

        response = await self.call_ollama(
            messages=messages,
            tools=mcp_tools,
        )

        assistant_message = response.get(
            "message",
            {},
        )

        # -----------------------------------------------------
        # STEP 5
        # Check whether Ollama requested a tool
        # -----------------------------------------------------

        tool_calls = assistant_message.get(
            "tool_calls",
            [],
        )

        # -----------------------------------------------------
        # No tool required
        # -----------------------------------------------------

        if not tool_calls:

            return assistant_message.get(
                "content",
                "",
            )

        # -----------------------------------------------------
        # STEP 6
        # Tool calls requested by LLM
        # -----------------------------------------------------

        messages.append(
            assistant_message
        )

        for tool_call in tool_calls:

            function = tool_call.get(
                "function",
                {},
            )

            tool_name = function.get(
                "name"
            )

            arguments = function.get(
                "arguments",
                {},
            )

            print(
                f"[AI] MCP tool requested: "
                f"{tool_name}"
            )

            print(
                f"[AI] Tool arguments: "
                f"{arguments}"
            )

            # -------------------------------------------------
            # Execute MCP tool
            # -------------------------------------------------

            result = await self.mcp_client.call_tool(
                tool_name,
                arguments,
            )

            # -------------------------------------------------
            # Convert MCP result to text
            # -------------------------------------------------

            tool_result_text = self.extract_tool_result(
                result
            )

            print(
                f"[AI] MCP tool result: "
                f"{tool_result_text}"
            )

            # -------------------------------------------------
            # Send result back to Ollama
            # -------------------------------------------------

            messages.append(
                {
                    "role": "tool",
                    "content": tool_result_text,
                }
            )

        # -----------------------------------------------------
        # STEP 7
        # Final LLM response
        # -----------------------------------------------------

        final_response = await self.call_ollama(
            messages=messages,
        )

        return final_response.get(
            "message",
            {},
        ).get(
            "content",
            "",
        )

    # ---------------------------------------------------------
    # MCP RESULT PARSER
    # ---------------------------------------------------------

    @staticmethod
    def extract_tool_result(
        result: Any,
    ) -> str:

        if hasattr(result, "content"):

            parts = []

            for item in result.content:

                if hasattr(item, "text"):

                    parts.append(
                        item.text
                    )

                else:

                    parts.append(
                        str(item)
                    )

            return "\n".join(parts)

        return str(result)
