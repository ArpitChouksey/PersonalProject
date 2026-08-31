import asyncio

from app.mcp_client import MCPClient


MCP_URL = "http://127.0.0.1:8000/mcp"


async def main():

    client = MCPClient(MCP_URL)

    await client.connect()

    print("\nMCP connected successfully.\n")

    tools = await client.list_tools()

    print("Available MCP tools:")

    for tool in tools:

        print(
            f"- {tool['name']}: "
            f"{tool['description']}"
        )

    print("\nCalling docker_list_containers...\n")

    result = await client.call_tool(
        "docker_list_containers",
        {},
    )

    print(result)

    await client.close()


if __name__ == "__main__":
    asyncio.run(main())
