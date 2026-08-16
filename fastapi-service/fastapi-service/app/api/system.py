from fastapi import APIRouter

from app.models.system import SystemInfoResponse
from app.services.system_service import SystemService


router = APIRouter()

system_service = SystemService()


@router.get(
    "/system",
    response_model=SystemInfoResponse,
)
def get_system_info() -> SystemInfoResponse:
    return system_service.get_system_info()
