from typing import Any

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


class MCPClientService:

    def __init__(
        self,
        server_url: str = "http://localhost:8000/mcp/",
    ):
        self.server_url = server_url

    async def list_tools(self) -> list[dict[str, Any]]:
        """
        Connect to the Python MCP server
        and discover available tools.
        """

        async with streamable_http_client(
            self.server_url
        ) as (
            read_stream,
            write_stream,
        ):

            async with ClientSession(
                read_stream,
                write_stream,
            ) as session:

                await session.initialize()

                result = await session.list_tools()

                return [
                    {
                        "name": tool.name,
                        "description": tool.description or "",
                        "input_schema": tool.input_schema,
                    }
                    for tool in result.tools
                ]

    async def call_tool(
        self,
        tool_name: str,
        arguments: dict[str, Any],
    ) -> Any:
        """
        Execute a tool on the Python MCP server.
        """

        async with streamable_http_client(
            self.server_url
        ) as (
            read_stream,
            write_stream,
        ):

            async with ClientSession(
                read_stream,
                write_stream,
            ) as session:

                await session.initialize()

                result = await session.call_tool(
                    tool_name,
                    arguments=arguments,
                )

                return result
