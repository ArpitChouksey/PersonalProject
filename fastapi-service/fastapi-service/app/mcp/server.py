from mcp.server import MCPServer

from app.mcp.tools import (
    calculate as calculate_service,
    get_system_info,
)


mcp = MCPServer(
    "Project9-Messaging-Python-MCP"
)


@mcp.tool(name="getSystemInfo")
def get_system_info_tool() -> dict:
    """
    Return information about the FastAPI service.
    """
    return get_system_info()


@mcp.tool(name="calculate")
def calculate_tool(
    operation: str,
    a: float,
    b: float,
) -> dict:
    """
    Perform a mathematical calculation.

    Supported operations:
    add, subtract, multiply, divide.
    """
    return calculate_service(
        operation=operation,
        a=a,
        b=b,
    )
