from fastapi import APIRouter, HTTPException

from app.rag.rag_service import RAGService

router = APIRouter(
    prefix="/rag",
    tags=["RAG"],
)

rag_service = RAGService()


@router.post("/ingest")
async def ingest_documents():

    try:
        return await rag_service.ingest()

    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"RAG ingestion failed: {exc}",
        )


@router.post("/search")
async def search_documents(
    request: dict,
):

    try:
        query = request.get("query")

        if not query:
            raise HTTPException(
                status_code=400,
                detail="query is required",
            )

        results = await rag_service.search(
            query=query,
            top_k=request.get("top_k", 3),
        )

        return results

    except HTTPException:
        raise

    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"RAG search failed: {exc}",
        )
