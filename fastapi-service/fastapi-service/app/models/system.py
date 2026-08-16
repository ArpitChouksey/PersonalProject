from pydantic import BaseModel


class SystemInfoResponse(BaseModel):
    service: str
    status: str
    framework: str
    language: str
    environment: str
