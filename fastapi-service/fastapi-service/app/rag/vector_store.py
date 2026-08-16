from pathlib import Path
from typing import Any

import chromadb


class VectorStore:

    def __init__(
        self,
        persist_directory: str = "./data/chroma",
        collection_name: str = "project9_documents",
    ):

        Path(persist_directory).mkdir(
            parents=True,
            exist_ok=True,
        )

        self.client = chromadb.PersistentClient(
            path=persist_directory
        )

        self.collection = (
            self.client.get_or_create_collection(
                name=collection_name
            )
        )

    def add_documents(
        self,
        documents: list[str],
        embeddings: list[list[float]],
        ids: list[str],
        metadatas: list[dict[str, Any]],
    ):

        self.collection.upsert(
            documents=documents,
            embeddings=embeddings,
            ids=ids,
            metadatas=metadatas,
        )

    def search(
        self,
        embedding: list[float],
        top_k: int = 3,
    ):

        return self.collection.query(
            query_embeddings=[embedding],
            n_results=top_k,
        )
