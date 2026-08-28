# app/agent/agent.py

from typing import Any, Dict

from app.agent.llm import call_llm
from app.agent.tool_loader import get_tools
from app.agent.formatter import format_tool_result


class KubernetesAgent:

    def __init__(self):

        self.tools = get_tools()


    def chat(
        self,
        message: str
    ) -> Dict[str, Any]:

        message = message.strip()

        if not message:

            return {
                "status": "error",
                "message": "Message cannot be empty."
            }


        decision = call_llm(
            message=message,
            tools=self.tools
        )


        # ================================================
        # NORMAL MESSAGE
        # ================================================

        if decision.get("type") == "message":

            return {
                "status": "success",
                "message": decision.get(
                    "message",
                    "How can I help you with Kubernetes?"
                )
            }


        # ================================================
        # TOOL CALL
        # ================================================

        if decision.get("type") == "tool_call":

            tool_name = decision.get("tool")

            arguments = decision.get(
                "arguments",
                {}
            )

            tool = self.tools.get(
                tool_name
            )


            if not tool:

                return {
                    "status": "error",
                    "message": f"Unknown tool: {tool_name}",
                    "tool": tool_name
                }


            try:

                result = tool["function"](
                    **arguments
                )

                return {
                    "status": "success",
                    "tool": tool_name,
                    "arguments": arguments,
                    "result": format_tool_result(
                        tool_name,
                        result
                    )
                }


            except Exception as error:

                return {
                    "status": "error",
                    "stage": "tool_execution",
                    "message": str(error),
                    "tool": tool_name
                }


        return {
            "status": "error",
            "message": "Unable to understand the request."
        }


_agent = KubernetesAgent()


def run_agent(
    message: str
):

    return _agent.chat(
        message
    )
