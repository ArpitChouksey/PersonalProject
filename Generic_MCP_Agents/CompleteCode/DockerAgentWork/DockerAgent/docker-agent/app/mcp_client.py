from typing import Any

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


class MCPClient:

    def __init__(self, server_url: str):
        self.server_url = server_url

        self._http_context = None
        self._session_context = None
        self.session = None

    async def connect(self):

        self._http_context = streamable_http_client(
            self.server_url
        )

        read_stream, write_stream = (
            await self._http_context.__aenter__()
        )

        self._session_context = ClientSession(
            read_stream,
            write_stream,
        )

        self.session = (
            await self._session_context.__aenter__()
        )

        await self.session.initialize()

    async def list_tools(self) -> list[dict[str, Any]]:

        if self.session is None:
            raise RuntimeError(
                "MCP client is not connected."
            )

        result = await self.session.list_tools()

        return [
            {
                "name": tool.name,
                "description": tool.description or "",
                "input_schema": tool.inputSchema,
            }
            for tool in result.tools
        ]

    async def call_tool(
        self,
        name: str,
        arguments: dict[str, Any],
    ):

        if self.session is None:
            raise RuntimeError(
                "MCP client is not connected."
            )

        return await self.session.call_tool(
            name,
            arguments,
        )

    async def close(self):

        if self._session_context:

            await self._session_context.__aexit__(
                None,
                None,
                None,
            )

        if self._http_context:

            await self._http_context.__aexit__(
                None,
                None,
                None,
            )
