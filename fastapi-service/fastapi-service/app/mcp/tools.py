from app.models.calculator import CalculateRequest
from app.services.calculator_service import CalculatorService
from app.services.system_service import SystemService


system_service = SystemService()
calculator_service = CalculatorService()


def get_system_info() -> dict:
    """
    Return information about the FastAPI service.
    """
    return system_service.get_system_info().model_dump()


def calculate(
    operation: str,
    a: float,
    b: float,
) -> dict:
    """
    Perform a mathematical calculation.

    Supported operations:
    add, subtract, multiply, divide.
    """

    request = CalculateRequest(
        operation=operation,
        a=a,
        b=b,
    )

    return calculator_service.calculate(
        request
    ).model_dump()
