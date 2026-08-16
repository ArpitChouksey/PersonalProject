from typing import Any

from pydantic import BaseModel


class UserSummaryResponse(BaseModel):
    user_id: str
    source: str
    data: Any
