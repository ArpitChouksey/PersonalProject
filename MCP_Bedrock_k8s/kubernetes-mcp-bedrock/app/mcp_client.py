import asyncio

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


MCP_SERVER_URL = "http://127.0.0.1:8080/mcp"


async def main():

    print(f"Connecting to: {MCP_SERVER_URL}")

    async with streamable_http_client(MCP_SERVER_URL) as (
        read_stream,
        write_stream,
    ):

        async with ClientSession(
            read_stream,
            write_stream
        ) as session:

            # ------------------------------------------------
            # 1. Initialize MCP session
            # ------------------------------------------------

            await session.initialize()

            print("\nConnected to Kubernetes MCP Server")


            # ------------------------------------------------
            # 2. Discover tools
            # ------------------------------------------------

            result = await session.list_tools()

            print("\nAvailable MCP tools:\n")

            for tool in result.tools:
                print(f"- {tool.name}")


            # ------------------------------------------------
            # 3. Call Kubernetes pods_list tool
            # ------------------------------------------------

            print("\nCalling pods_list...\n")

            result = await session.call_tool(
                "pods_list",
                arguments={}
            )


            # ------------------------------------------------
            # 4. Print result
            # ------------------------------------------------

            print("Kubernetes MCP result:\n")

            for content in result.content:

                if hasattr(content, "text"):
                    print(content.text)


if __name__ == "__main__":
    asyncio.run(main())
