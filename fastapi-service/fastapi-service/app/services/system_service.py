from app.config.settings import settings
from app.models.system import SystemInfoResponse


class SystemService:

    def get_system_info(self) -> SystemInfoResponse:
        return SystemInfoResponse(
            service=settings.app_name,
            status="UP",
            framework="FastAPI",
            language="Python",
            environment=settings.environment,
        )
