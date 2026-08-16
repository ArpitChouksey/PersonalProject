from typing import Any

import httpx


class EmbeddingService:

    def __init__(
        self,
        ollama_url: str = "http://127.0.0.1:11434",
        model: str = "nomic-embed-text",
    ):
        self.ollama_url = ollama_url.rstrip("/")
        self.model = model

    async def embed(
        self,
        text: str,
    ) -> list[float]:

        payload = {
            "model": self.model,
            "input": text,
        }

        async with httpx.AsyncClient(
            timeout=120.0
        ) as client:

            response = await client.post(
                f"{self.ollama_url}/api/embed",
                json=payload,
            )

            response.raise_for_status()

            data = response.json()

            return data["embeddings"][0]
