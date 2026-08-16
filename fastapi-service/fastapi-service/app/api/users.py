from fastapi import APIRouter, HTTPException

from app.models.user import UserSummaryResponse
from app.services.user_summary_service import UserSummaryService


router = APIRouter()

user_summary_service = UserSummaryService()


@router.get(
    "/users/{user_id}/summary",
    response_model=UserSummaryResponse,
)
def get_user_summary(
    user_id: str,
) -> UserSummaryResponse:

    try:
        return user_summary_service.get_user_summary(
            user_id
        )

    except RuntimeError as exc:
        raise HTTPException(
            status_code=502,
            detail=str(exc),
        ) from exc
