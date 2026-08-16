from app.rag.document_loader import DocumentLoader
from app.rag.chunker import TextChunker
from app.rag.embedding_service import EmbeddingService
from app.rag.vector_store import VectorStore


class RAGService:

    def __init__(self):

        self.loader = DocumentLoader()

        self.chunker = TextChunker()

        self.embedding_service = (
            EmbeddingService()
        )

        self.vector_store = VectorStore()

    async def ingest(self):

        documents = self.loader.load()

        all_chunks = []
        all_embeddings = []
        all_ids = []
        all_metadatas = []

        counter = 0

        for document in documents:

            chunks = self.chunker.chunk(
                document["content"]
            )

            for chunk in chunks:

                embedding = (
                    await self.embedding_service.embed(
                        chunk
                    )
                )

                all_chunks.append(chunk)

                all_embeddings.append(
                    embedding
                )

                all_ids.append(
                    f"chunk-{counter}"
                )

                all_metadatas.append(
                    {
                        "source": document[
                            "source"
                        ]
                    }
                )

                counter += 1

        if all_chunks:

            self.vector_store.add_documents(
                documents=all_chunks,
                embeddings=all_embeddings,
                ids=all_ids,
                metadatas=all_metadatas,
            )

        return {
            "documents": len(documents),
            "chunks": len(all_chunks),
        }

    async def search(
        self,
        query: str,
        top_k: int = 3,
    ):

        query_embedding = (
            await self.embedding_service.embed(
                query
            )
        )

        results = self.vector_store.search(
            query_embedding,
            top_k,
        )

        return results
