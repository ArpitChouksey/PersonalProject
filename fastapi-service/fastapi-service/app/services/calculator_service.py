from app.models.calculator import (
    CalculateRequest,
    CalculateResponse,
)


class CalculatorService:

    def calculate(
        self,
        request: CalculateRequest,
    ) -> CalculateResponse:

        if request.operation == "add":
            result = request.a + request.b

        elif request.operation == "subtract":
            result = request.a - request.b

        elif request.operation == "multiply":
            result = request.a * request.b

        elif request.operation == "divide":
            if request.b == 0:
                raise ValueError(
                    "Division by zero is not allowed"
                )

            result = request.a / request.b

        else:
            raise ValueError(
                f"Unsupported operation: {request.operation}"
            )

        return CalculateResponse(
            operation=request.operation,
            a=request.a,
            b=request.b,
            result=result,
        )
