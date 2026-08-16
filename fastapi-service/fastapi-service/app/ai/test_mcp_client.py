import asyncio

from app.ai.mcp_client import MCPClientService


async def main():

    client = MCPClientService()

    tools = await client.list_tools()

    print("Available tools:")

    for tool in tools:
        print(f"- {tool['name']}")

    result = await client.call_tool(
        "calculate",
        {
            "operation": "add",
            "a": 100,
            "b": 250,
        },
    )

    print("\nTool result:")
    print(result)


if __name__ == "__main__":
    asyncio.run(main())
