from typing import Any


def mcp_tools_to_ollama_tools(
    mcp_tools: list[dict[str, Any]],
) -> list[dict[str, Any]]:

    tools = []

    for tool in mcp_tools:

        tools.append(
            {
                "type": "function",
                "function": {
                    "name": tool["name"],
                    "description": tool["description"],
                    "parameters": tool["input_schema"],
                },
            }
        )

    return tools
