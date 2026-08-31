import asyncio
import json
import os
from contextlib import AsyncExitStack
from typing import Any

import boto3

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


# ============================================================
# CONFIGURATION
# ============================================================

STANDARD_MCP_URL = "http://127.0.0.1:8080/mcp"
CUSTOM_MCP_URL = "http://127.0.0.1:8081/mcp"

AWS_REGION = os.getenv(
    "AWS_REGION",
    "us-east-1",
)

# Change this only if you are using another Bedrock model.
BEDROCK_MODEL_ID = os.getenv(
    "BEDROCK_MODEL_ID",
    "amazon.nova-lite-v1:0",
)


# ============================================================
# BEDROCK CLIENT
# ============================================================

bedrock = boto3.client(
    "bedrock-runtime",
    region_name=AWS_REGION,
)


# ============================================================
# SYSTEM PROMPT
# ============================================================

SYSTEM_PROMPT = """
You are a Kubernetes AI Agent.

You have access to Kubernetes tools provided through MCP servers.

IMPORTANT RULES:

1. Use a Kubernetes MCP tool when the user asks about the cluster.
2. Choose the single most appropriate tool for the user's request.
3. Do not call unrelated tools.
4. Do not list available tools to the user.
5. Do not expose MCP implementation details to the user.
6. If the user asks for all pods, use pods_list.
7. If the user asks for namespaces, use namespaces_list.
8. If the user asks for a pod in a specific namespace, use the appropriate pod tool.
9. If the user asks to restart a pod, use restart_pod.
10. For restart_pod, obtain the pod name and namespace from the user's request.
11. Never invent Kubernetes resource information.
12. The application will return the Kubernetes tool result directly to the user.
"""


# ============================================================
# MCP TOOL STORAGE
# ============================================================

class MCPTool:
    """
    Keeps the MCP tool together with the MCP session
    that owns the tool.
    """

    def __init__(
        self,
        tool: Any,
        session: ClientSession,
        server_name: str,
    ):
        self.tool = tool
        self.session = session
        self.server_name = server_name


# ============================================================
# MCP TOOL -> BEDROCK TOOL CONVERSION
# ============================================================

def get_tool_schema(tool: Any) -> dict:
    """
    MCP SDK versions may expose the schema as either:

        input_schema

    or:

        inputSchema

    Your installed MCP 1.29.1 exposes input_schema.
    """

    schema = getattr(
        tool,
        "input_schema",
        None,
    )

    if schema is None:
        schema = getattr(
            tool,
            "inputSchema",
            None,
        )

    if schema is None:
        schema = {
            "type": "object",
            "properties": {},
        }

    return schema


def convert_mcp_tool_to_bedrock(
    tool: Any,
) -> dict:
    """
    Convert an MCP Tool definition into
    Amazon Bedrock Converse toolSpec format.
    """

    name = tool.name

    description = (
        getattr(tool, "description", None)
        or f"Kubernetes MCP tool: {name}"
    )

    input_schema = get_tool_schema(tool)

    return {
        "toolSpec": {
            "name": name,
            "description": description,
            "inputSchema": {
                "json": input_schema,
            },
        }
    }


# ============================================================
# MCP RESULT -> TEXT
# ============================================================

def mcp_result_to_text(
    result: Any,
) -> str:
    """
    Convert an MCP CallToolResult into a clean
    string that can be returned to the UI.
    """

    parts = []

    # --------------------------------------------------------
    # Normal MCP text content
    # --------------------------------------------------------

    content = getattr(
        result,
        "content",
        None,
    )

    if content:

        for item in content:

            text = getattr(
                item,
                "text",
                None,
            )

            if text:
                parts.append(
                    str(text)
                )

    # --------------------------------------------------------
    # Structured MCP output
    # --------------------------------------------------------

    if not parts:

        structured = getattr(
            result,
            "structuredContent",
            None,
        )

        if structured is None:
            structured = getattr(
                result,
                "structured_content",
                None,
            )

        if structured is not None:

            try:

                if isinstance(
                    structured,
                    str,
                ):
                    return structured

                return json.dumps(
                    structured,
                    indent=2,
                    default=str,
                )

            except Exception:
                return str(structured)

    # --------------------------------------------------------
    # Final result
    # --------------------------------------------------------

    if parts:

        return "\n".join(parts)

    return str(result)


# ============================================================
# CONNECT TO MCP SERVERS
# ============================================================

async def connect_mcp_servers(
    exit_stack: AsyncExitStack,
):
    """
    Connect to both:

        Standard MCP :8080
        Custom MCP   :8081

    Returns:

        sessions
        tools
    """

    print()
    print("=" * 60)
    print("[MCP] Connecting to Kubernetes MCP servers")
    print("=" * 60)

    sessions = []

    all_tools = {}

    # ========================================================
    # STANDARD MCP
    # ========================================================

    print()
    print(
        f"[MCP] Connecting standard MCP: "
        f"{STANDARD_MCP_URL}"
    )

    (
        standard_read,
        standard_write,
        standard_session_id,
    ) = await exit_stack.enter_async_context(
        streamable_http_client(
            STANDARD_MCP_URL
        )
    )

    standard_session = await exit_stack.enter_async_context(
        ClientSession(
            standard_read,
            standard_write,
        )
    )

    await standard_session.initialize()

    print(
        "[MCP] Standard MCP connected"
    )

    standard_tools_result = (
        await standard_session.list_tools()
    )

    standard_tools = (
        standard_tools_result.tools
    )

    print(
        f"[MCP] Standard MCP tools: "
        f"{len(standard_tools)}"
    )

    sessions.append(
        {
            "name": "standard",
            "session": standard_session,
        }
    )

    for tool in standard_tools:

        all_tools[tool.name] = MCPTool(
            tool=tool,
            session=standard_session,
            server_name="standard",
        )

    # ========================================================
    # CUSTOM MCP
    # ========================================================

    print()
    print(
        f"[MCP] Connecting custom MCP: "
        f"{CUSTOM_MCP_URL}"
    )

    (
        custom_read,
        custom_write,
        custom_session_id,
    ) = await exit_stack.enter_async_context(
        streamable_http_client(
            CUSTOM_MCP_URL
        )
    )

    custom_session = await exit_stack.enter_async_context(
        ClientSession(
            custom_read,
            custom_write,
        )
    )

    await custom_session.initialize()

    print(
        "[MCP] Custom MCP connected"
    )

    custom_tools_result = (
        await custom_session.list_tools()
    )

    custom_tools = (
        custom_tools_result.tools
    )

    print(
        f"[MCP] Custom MCP tools: "
        f"{len(custom_tools)}"
    )

    sessions.append(
        {
            "name": "custom",
            "session": custom_session,
        }
    )

    for tool in custom_tools:

        if tool.name in all_tools:

            print(
                f"[MCP] WARNING: duplicate tool "
                f"name detected: {tool.name}"
            )

        all_tools[tool.name] = MCPTool(
            tool=tool,
            session=custom_session,
            server_name="custom",
        )

    # ========================================================
    # SUMMARY
    # ========================================================

    print()
    print(
        f"[MCP] Total tools discovered: "
        f"{len(all_tools)}"
    )

    print(
        "[MCP] Standard MCP + Custom MCP ready"
    )

    return sessions, all_tools


# ============================================================
# ASK BEDROCK TO SELECT A TOOL
# ============================================================

async def ask_bedrock(
    user_prompt: str,
    tools: dict[str, MCPTool],
):
    """
    Ask Bedrock which MCP tool should be called.
    """

    bedrock_tools = []

    for mcp_tool in tools.values():

        bedrock_tools.append(
            convert_mcp_tool_to_bedrock(
                mcp_tool.tool
            )
        )

    # ========================================================
    # USER MESSAGE
    # ========================================================

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "text": user_prompt
                }
            ],
        }
    ]

    # ========================================================
    # BEDROCK REQUEST
    # ========================================================

    response = bedrock.converse(
        modelId=BEDROCK_MODEL_ID,

        system=[
            {
                "text": SYSTEM_PROMPT
            }
        ],

        messages=messages,

        toolConfig={
            "tools": bedrock_tools
        },

        inferenceConfig={
            "maxTokens": 500,
            "temperature": 0,
        },
    )

    return response


# ============================================================
# EXTRACT TOOL USE
# ============================================================

def extract_tool_use(
    response: dict,
):
    """
    Extract the toolUse block from a Bedrock response.
    """

    output = response.get(
        "output",
        {},
    )

    message = output.get(
        "message",
        {},
    )

    content = message.get(
        "content",
        [],
    )

    for block in content:

        tool_use = block.get(
            "toolUse"
        )

        if tool_use:

            return tool_use

    return None


# ============================================================
# MAIN AGENT
# ============================================================

async def run_agent(
    user_prompt: str,
) -> str:

    print()
    print("=" * 60)
    print("[Agent] Starting")
    print("=" * 60)

    print(
        f"[Agent] User: {user_prompt}"
    )

    # ========================================================
    # KEEP MCP CONNECTIONS ALIVE
    # ========================================================

    async with AsyncExitStack() as exit_stack:

        try:

            (
                sessions,
                tools,
            ) = await connect_mcp_servers(
                exit_stack
            )

        except Exception as e:

            print()
            print(
                "[MCP] Connection error"
            )

            print(
                repr(e)
            )

            raise

        # ====================================================
        # ASK BEDROCK
        # ====================================================

        print()
        print(
            "[Bedrock] Selecting Kubernetes tool..."
        )

        try:

            response = await asyncio.to_thread(
                ask_bedrock_sync,
                user_prompt,
                tools,
            )

        except Exception as e:

            print()
            print(
                "[Bedrock] ERROR"
            )

            print(
                repr(e)
            )

            raise

        # ====================================================
        # TOOL REQUEST
        # ====================================================

        tool_use = extract_tool_use(
            response
        )

        if not tool_use:

            # ------------------------------------------------
            # Bedrock answered without a tool.
            # ------------------------------------------------

            output = response.get(
                "output",
                {},
            )

            message = output.get(
                "message",
                {},
            )

            content = message.get(
                "content",
                [],
            )

            text_parts = []

            for block in content:

                text = block.get(
                    "text"
                )

                if text:
                    text_parts.append(
                        text
                    )

            if text_parts:

                return "\n".join(
                    text_parts
                )

            return (
                "I could not determine "
                "the appropriate Kubernetes operation."
            )

        # ====================================================
        # TOOL NAME
        # ====================================================

        tool_name = tool_use.get(
            "name"
        )

        tool_input = tool_use.get(
            "input",
            {},
        )

        print()
        print("=" * 60)
        print("[Agent] MCP Tool Requested")
        print("=" * 60)

        print(
            f"Tool: {tool_name}"
        )

        print(
            f"Server: "
            f"{tools[tool_name].server_name}"
            if tool_name in tools
            else "Server: unknown"
        )

        print(
            f"Input: {json.dumps(tool_input, indent=2)}"
        )

        # ====================================================
        # VALIDATE TOOL
        # ====================================================

        if tool_name not in tools:

            return (
                f"Unknown Kubernetes tool: "
                f"{tool_name}"
            )

        mcp_tool = tools[
            tool_name
        ]

        # ====================================================
        # CALL MCP TOOL
        # ====================================================

        print()
        print(
            "[MCP] Calling tool..."
        )

        try:

            result = await mcp_tool.session.call_tool(
                tool_name,
                arguments=tool_input,
            )

        except Exception as e:

            print()
            print(
                "[MCP] Tool execution failed"
            )

            print(
                repr(e)
            )

            return (
                f"Failed to execute "
                f"Kubernetes tool '{tool_name}': "
                f"{str(e)}"
            )

        # ====================================================
        # MCP RESULT
        # ====================================================

        print()
        print(
            "[MCP] Tool executed successfully"
        )

        result_text = mcp_result_to_text(
            result
        )

        print()
        print(
            "[Agent] Returning MCP result directly "
            "to user"
        )

        return result_text


# ============================================================
# SYNCHRONOUS BEDROCK HELPER
# ============================================================

def ask_bedrock_sync(
    user_prompt: str,
    tools: dict[str, MCPTool],
):
    """
    boto3 is synchronous, so run it in a worker thread.
    """

    bedrock_tools = []

    for mcp_tool in tools.values():

        bedrock_tools.append(
            convert_mcp_tool_to_bedrock(
                mcp_tool.tool
            )
        )

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "text": user_prompt
                }
            ],
        }
    ]

    response = bedrock.converse(
        modelId=BEDROCK_MODEL_ID,

        system=[
            {
                "text": SYSTEM_PROMPT
            }
        ],

        messages=messages,

        toolConfig={
            "tools": bedrock_tools
        },

        inferenceConfig={
            "maxTokens": 500,
            "temperature": 0,
        },
    )

    stop_reason = response.get(
        "stopReason"
    )

    print(
        f"[Bedrock] stopReason: "
        f"{stop_reason}"
    )

    return response


# ============================================================
# CLI
# ============================================================

async def main():

    print()
    print("=" * 60)
    print("Kubernetes Agent")
    print("Bedrock + MCP + Kubernetes")
    print("=" * 60)

    user_prompt = input(
        "Ask Kubernetes something: "
    ).strip()

    if not user_prompt:

        print(
            "No question provided."
        )

        return

    print()
    print(
        f"User: {user_prompt}"
    )

    try:

        answer = await run_agent(
            user_prompt
        )

        print()
        print("=" * 60)
        print("Agent Response")
        print("=" * 60)
        print()
        print(answer)

    except Exception as e:

        print()
        print("=" * 60)
        print("Agent Error")
        print("=" * 60)
        print()
        print(
            str(e)
        )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":

    asyncio.run(
        main()
    )
