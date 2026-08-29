from typing import Any, Dict, Optional

from pydantic import BaseModel


class AgentResponse(BaseModel):

    status: str

    tool: Optional[str] = None

    arguments: Optional[Dict[str, Any]] = None

    result: Optional[Any] = None

    message: Optional[str] = None
