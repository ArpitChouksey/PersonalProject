from typing import Any

import httpx


class LLMService:

    def __init__(
        self,
        ollama_url: str = "http://127.0.0.1:11434",
        model: str = "llama3.2",
    ):
        self.ollama_url = ollama_url.rstrip("/")
        self.model = model

    async def chat(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:

        payload: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "stream": False,
        }

        if tools:
            payload["tools"] = tools

        print("\n========== OLLAMA REQUEST ==========")
        print(payload)

        async with httpx.AsyncClient(
            timeout=120.0
        ) as client:

            response = await client.post(
                f"{self.ollama_url}/api/chat",
                json=payload,
            )

            response.raise_for_status()

            data = response.json()

        print("\n========== OLLAMA RESPONSE ==========")
        print(data)

        return data
