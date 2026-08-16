from fastapi import APIRouter, HTTPException

from app.models.calculator import (
    CalculateRequest,
    CalculateResponse,
)
from app.services.calculator_service import CalculatorService


router = APIRouter()

calculator_service = CalculatorService()


@router.post(
    "/calculate",
    response_model=CalculateResponse,
)
def calculate(
    request: CalculateRequest,
) -> CalculateResponse:

    try:
        return calculator_service.calculate(request)

    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc
