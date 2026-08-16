from typing import Literal

from pydantic import BaseModel, Field


class CalculateRequest(BaseModel):
    operation: Literal[
        "add",
        "subtract",
        "multiply",
        "divide",
    ]

    a: float = Field(
        ...,
        description="First number",
    )

    b: float = Field(
        ...,
        description="Second number",
    )


class CalculateResponse(BaseModel):
    operation: str
    a: float
    b: float
    result: float
