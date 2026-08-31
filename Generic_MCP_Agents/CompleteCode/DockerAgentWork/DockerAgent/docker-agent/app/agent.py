import json
import urllib.request
import urllib.error

from app.tool_registry import list_tools, execute_tool


OLLAMA_URL = "http://127.0.0.1:11434/api/chat"
OLLAMA_MODEL = "llama3.2"


SYSTEM_PROMPT = """
You are a Docker DevOps agent.

Your job is to help users operate and troubleshoot Docker
using the tools provided by the application.

Rules:

1. Use available tools when real Docker information is required.
2. Do not invent container names, image names or command results.
3. Read-only tools can be used when necessary.
4. Write operations require explicit user confirmation.
5. Explain errors clearly.
6. Prefer Docker CLI based operations.
7. If multiple tools are needed, execute them one at a time.
8. After receiving tool results, analyze them and provide a concise
   DevOps-oriented answer.
"""


def _build_tool_definitions():
    tools = []

    for name, definition in list_tools().items():

        properties = {}

        required = []

        for parameter_name, parameter in definition.get(
            "parameters",
            {}
        ).items():

            properties[parameter_name] = {
                "type": parameter.get(
                    "type",
                    "string"
                ),
                "description": parameter.get(
                    "description",
                    ""
                )
            }

            required.append(parameter_name)

        tools.append({
            "type": "function",
            "function": {
                "name": name,
                "description": definition["description"],
                "parameters": {
                    "type": "object",
                    "properties": properties,
                    "required": required
                }
            }
        })

    return tools


def _ollama_chat(messages, tools=None):

    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": False
    }

    if tools:
        payload["tools"] = tools

    data = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(
        OLLAMA_URL,
        data=data,
        headers={
            "Content-Type": "application/json"
        },
        method="POST"
    )

    try:

        with urllib.request.urlopen(
            request,
            timeout=300
        ) as response:

            body = response.read().decode("utf-8")

            return json.loads(body)

    except urllib.error.URLError as error:

        return {
            "error": (
                "Unable to connect to Ollama: "
                f"{error}"
            )
        }

    except Exception as error:

        return {
            "error": str(error)
        }


def _tool_result_to_text(result):

    try:
        return json.dumps(
            result,
            indent=2,
            default=str
        )

    except Exception:
        return str(result)


def run_agent(user_message):

    tools = _build_tool_definitions()

    messages = [
        {
            "role": "system",
            "content": SYSTEM_PROMPT
        },
        {
            "role": "user",
            "content": user_message
        }
    ]

    max_iterations = 8

    for _ in range(max_iterations):

        response = _ollama_chat(
            messages,
            tools
        )

        if "error" in response:
            return {
                "success": False,
                "answer": response["error"]
            }

        message = response.get(
            "message",
            {}
        )

        tool_calls = message.get(
            "tool_calls",
            []
        )

        if not tool_calls:

            return {
                "success": True,
                "answer": message.get(
                    "content",
                    ""
                )
            }

        messages.append(message)

        for tool_call in tool_calls:

            function = tool_call.get(
                "function",
                {}
            )

            tool_name = function.get(
                "name"
            )

            arguments = function.get(
                "arguments",
                {}
            )

            if not isinstance(arguments, dict):
                arguments = {}

            tool = list_tools().get(
                tool_name
            )

            if not tool:

                result = {
                    "return_code": 1,
                    "error": (
                        f"Unknown tool requested: "
                        f"{tool_name}"
                    )
                }

            else:

                # Read operations can execute automatically.
                # Write operations must be confirmed by the CLI
                # application before being exposed to the agent.
                if tool["risk"] == "write":

                    result = {
                        "return_code": 1,
                        "error": (
                            f"Write operation '{tool_name}' "
                            "requires explicit confirmation "
                            "in interactive tool mode."
                        )
                    }

                else:

                    result = execute_tool(
                        tool_name,
                        **arguments
                    )

            messages.append({
                "role": "tool",
                "content": _tool_result_to_text(
                    result
                )
            })

    return {
        "success": False,
        "answer": (
            "Agent stopped because the maximum "
            "tool-call iterations were reached."
        )
    }
