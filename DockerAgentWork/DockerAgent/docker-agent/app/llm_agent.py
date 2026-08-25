import json
import os
from typing import Any

import requests


class DockerLLMAgent:

    def __init__(self, tools: dict[str, Any]):
        self.tools = tools

        self.ollama_base_url = os.getenv(
            "OLLAMA_BASE_URL",
            "http://host.docker.internal:11434",
        ).rstrip("/")

        self.model = os.getenv(
            "OLLAMA_MODEL",
            "llama3.2:latest",
        )

    # ---------------------------------------------------------
    # Ollama
    # ---------------------------------------------------------

    def _call_ollama(self, prompt: str) -> str:

        url = f"{self.ollama_base_url}/api/generate"

        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
        }

        response = requests.post(
            url,
            json=payload,
            timeout=120,
        )

        response.raise_for_status()

        data = response.json()

        return data.get("response", "").strip()

    # ---------------------------------------------------------
    # Tool selection
    # ---------------------------------------------------------

    def _select_tool(self, user_message: str):

        tool_names = list(self.tools.keys())

        prompt = f"""
You are an AI operations assistant.

Available tools:

{json.dumps(tool_names, indent=2)}

User request:

{user_message}

Select the most appropriate tool.

Return ONLY JSON.

Format:

{{
    "tool": "tool_name",
    "arguments": {{}}
}}

If no tool is required:

{{
    "tool": null,
    "arguments": {{}}
}}

Rules:

- Docker containers -> docker_ps
- Docker images -> docker_images
- Docker container inspection -> docker_container_inspect
- Docker logs -> docker_container_logs
- Linux processes -> process_list
- Disk usage -> disk_usage
- Memory -> memory_usage

Do not return markdown.
Do not explain your answer.
"""

        try:

            response = self._call_ollama(prompt)

            response = response.replace(
                "```json",
                "",
            ).replace(
                "```",
                "",
            ).strip()

            data = json.loads(response)

            return (
                data.get("tool"),
                data.get("arguments", {}),
            )

        except Exception:

            # Simple deterministic fallback.
            text = user_message.lower()

            if "image" in text:
                return "docker_images", {}

            if (
                "container" in text
                or "docker ps" in text
            ):
                return "docker_ps", {}

            if (
                "process" in text
                or "running process" in text
            ):
                return "process_list", {}

            if (
                "disk" in text
                or "storage" in text
            ):
                return "disk_usage", {}

            if "memory" in text:
                return "memory_usage", {}

            return None, {}

    # ---------------------------------------------------------
    # Tool execution
    # ---------------------------------------------------------

    def _execute_tool(
        self,
        tool_name: str,
        arguments: dict,
    ):

        tool = self.tools.get(tool_name)

        if tool is None:

            return {
                "status": "ERROR",
                "message": (
                    f"Tool '{tool_name}' "
                    "does not exist"
                ),
            }

        try:

            return tool(**arguments)

        except Exception as exc:

            return {
                "status": "ERROR",
                "message": str(exc),
            }

    # ---------------------------------------------------------
    # Detect requested fields
    # ---------------------------------------------------------

    def _requested_fields(
        self,
        user_message: str,
        data: list[dict],
    ):

        if not data:
            return []

        available_fields = list(data[0].keys())

        prompt = f"""
The user wants data from a system command.

User request:

{user_message}

Available fields:

{json.dumps(available_fields)}

Determine which fields the user requested.

Examples:

"show name and status"

=> ["name", "status"]

"show image and size"

=> ["repository", "tag", "size"]

"show user and command"

=> ["user", "command"]

"show everything"

=> all available fields

Return ONLY a JSON array.

Example:

["name", "status"]
"""

        try:

            response = self._call_ollama(prompt)

            response = response.replace(
                "```json",
                "",
            ).replace(
                "```",
                "",
            ).strip()

            fields = json.loads(response)

            if not isinstance(fields, list):
                return available_fields

            valid_fields = [
                field
                for field in fields
                if field in available_fields
            ]

            if valid_fields:
                return valid_fields

        except Exception:
            pass

        # Default fields
        return available_fields

    # ---------------------------------------------------------
    # Format table
    # ---------------------------------------------------------

    def _build_markdown_table(
        self,
        data: list[dict],
        fields: list[str],
    ):

        if not data:
            return "No data found."

        if not fields:
            fields = list(data[0].keys())

        headers = [
            field.replace("_", " ").title()
            for field in fields
        ]

        lines = []

        lines.append(
            "| " + " | ".join(headers) + " |"
        )

        lines.append(
            "| "
            + " | ".join(["---"] * len(fields))
            + " |"
        )

        for item in data:

            values = []

            for field in fields:

                value = item.get(field, "")

                value = str(value).replace(
                    "|",
                    "\\|",
                ).replace(
                    "\n",
                    " ",
                )

                values.append(value)

            lines.append(
                "| " + " | ".join(values) + " |"
            )

        return "\n".join(lines)

    # ---------------------------------------------------------
    # Main
    # ---------------------------------------------------------

    def run(self, message: str):

        tool_name, arguments = self._select_tool(
            message
        )

        # No tool required
        if not tool_name:

            try:

                answer = self._call_ollama(
                    message
                )

            except Exception as exc:

                answer = (
                    "Unable to contact Ollama: "
                    f"{exc}"
                )

            return {
                "status": "SUCCESS",
                "message": answer,
                "tool_calls": [],
            }

        # Execute selected tool
        tool_result = self._execute_tool(
            tool_name,
            arguments,
        )

        if not isinstance(tool_result, dict):

            return {
                "status": "SUCCESS",
                "message": str(tool_result),
                "tool_calls": [
                    {
                        "tool": tool_name,
                        "status": "SUCCESS",
                        "result": tool_result,
                    }
                ],
            }

        # Tool failed
        if tool_result.get("status") != "SUCCESS":

            return {
                "status": "SUCCESS",
                "message": (
                    "Tool execution failed:\n\n"
                    f"**Error:** "
                    f"{tool_result.get('stderr') or tool_result.get('message', 'Unknown error')}"
                ),
                "tool_calls": [
                    {
                        "tool": tool_name,
                        "status": "ERROR",
                        "result": tool_result,
                    }
                ],
            }

        data = tool_result.get("data")

        # Structured result
        if isinstance(data, list):

            fields = self._requested_fields(
                message,
                data,
            )

            table = self._build_markdown_table(
                data,
                fields,
            )

            answer = table

        else:

            stdout = tool_result.get(
                "stdout",
                "",
            )

            answer = (
                f"```text\n{stdout}\n```"
                if stdout
                else "Command completed successfully."
            )

        return {
            "status": "SUCCESS",
            "message": answer,
            "tool_calls": [
                {
                    "tool": tool_name,
                    "status": "SUCCESS",
                    "result": tool_result,
                }
            ],
        }

    def chat(self, message: str):
        return self.run(message)
