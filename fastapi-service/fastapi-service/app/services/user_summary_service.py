import httpx

from app.config.settings import settings
from app.models.user import UserSummaryResponse


class UserSummaryService:

    def get_user_summary(
        self,
        user_id: str,
    ) -> UserSummaryResponse:

        url = (
            f"{settings.spring_service_url}"
            f"/users/{user_id}"
        )

        try:
            response = httpx.get(
                url,
                timeout=10.0,
            )

            response.raise_for_status()

            return UserSummaryResponse(
                user_id=user_id,
                source="spring-service",
                data=response.json(),
            )

        except httpx.HTTPError as exc:
            raise RuntimeError(
                "Failed to communicate with "
                f"Spring Service: {exc}"
            ) from exc
