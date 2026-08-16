from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(
        ...,
        min_length=1,
        description="Message sent to the LLM",
    )


class ChatResponse(BaseModel):
    response: str
    model: str
