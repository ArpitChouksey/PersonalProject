from fastapi import APIRouter, HTTPException

from app.ai.ai_service import AIService
from app.ai.schemas import ChatRequest, ChatResponse


router = APIRouter(
    prefix="/ai",
    tags=["AI"],
)


ai_service = AIService()


@router.post(
    "/chat",
    response_model=ChatResponse,
)
async def chat(
    request: ChatRequest,
):

    try:

        response = await ai_service.chat(
            request.message
        )

        return ChatResponse(
            response=response,
            model=ai_service.model,
        )

    except Exception as exc:

        raise HTTPException(
            status_code=500,
            detail=f"AI processing failed: {exc}",
        )
