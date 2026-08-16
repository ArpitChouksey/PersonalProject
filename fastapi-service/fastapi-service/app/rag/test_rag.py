import asyncio

from app.rag.rag_service import RAGService


async def main():

    rag = RAGService()

    print("Ingesting documents...")

    result = await rag.ingest()

    print(result)

    print("\nSearching...")

    results = await rag.search(
        "How does Project9 expose MCP?",
        top_k=3,
    )

    print("\nResults:")

    for document in results["documents"][0]:

        print("\n---")

        print(document)


if __name__ == "__main__":
    asyncio.run(main())
