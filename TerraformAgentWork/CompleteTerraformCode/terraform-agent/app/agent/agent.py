import os

import ollama

from app.agent.prompts import SYSTEM_PROMPT
from app.config import OLLAMA_HOST, OLLAMA_MODEL
from app.session import session_manager
from app.tools.registry import (
    execute_tool,
    get_tools
)


class TerraformAgent:

    def __init__(self):

        self.client = ollama.Client(
            host=OLLAMA_HOST
        )

    # ========================================================
    # Get Current Session
    # ========================================================

    def get_session_id(self):

        return (
            session_manager
            .get_default_session_id()
        )

    # ========================================================
    # Get Terraform Path
    # ========================================================

    def get_path(
        self,
        session_id
    ):

        return (
            session_manager
            .get_terraform_path(
                session_id
            )
        )

    # ========================================================
    # Set Terraform Path
    # ========================================================

    def set_path(
        self,
        session_id,
        terraform_path
    ):

        terraform_path = os.path.abspath(
            os.path.expanduser(
                terraform_path
            )
        )

        if not os.path.isdir(
            terraform_path
        ):

            return {
                "status": "error",
                "message": (
                    "Terraform path does not exist "
                    "or is not a directory.",
                    terraform_path
                )
            }

        session_manager.set_terraform_path(
            session_id,
            terraform_path
        )

        return {
            "status": "success",
            "terraform_path": terraform_path
        }

    # ========================================================
    # Extract Path
    # ========================================================

    @staticmethod
    def extract_path(
        message: str
    ):

        message = message.strip()

        # Direct path
        if (
            message.startswith("/")
            and " " not in message
        ):
            return message

        prefixes = [
            "terraform path:",
            "terraform path :",
            "path:",
            "path :"
        ]

        lower_message = (
            message.lower()
        )

        for prefix in prefixes:

            if lower_message.startswith(
                prefix
            ):

                return message[
                    len(prefix):
                ].strip()

        return None

    # ========================================================
    # Chat
    # ========================================================

    def chat(
        self,
        message: str
    ):

        session_id = (
            self.get_session_id()
        )

        terraform_path = (
            self.get_path(
                session_id
            )
        )

        # ----------------------------------------------------
        # Check whether message contains path
        # ----------------------------------------------------

        possible_path = (
            self.extract_path(
                message
            )
        )

        if possible_path:

            path_result = (
                self.set_path(
                    session_id,
                    possible_path
                )
            )

            if path_result["status"] == "error":

                return path_result

            terraform_path = (
                path_result[
                    "terraform_path"
                ]
            )

            # If user only provided a path
            return {
                "status": "success",
                "message": (
                    "Terraform path saved."
                ),
                "terraform_path":
                    terraform_path
            }

        # ----------------------------------------------------
        # Ask Ollama
        # ----------------------------------------------------

        response = self.client.chat(

            model=OLLAMA_MODEL,

            messages=[

                {
                    "role": "system",
                    "content": SYSTEM_PROMPT
                },

                {
                    "role": "user",
                    "content": message
                }
            ],

            tools=get_tools()
        )

        # ----------------------------------------------------
        # No tool call
        # ----------------------------------------------------

        if not response.message.tool_calls:

            return {
                "status": "success",
                "message": (
                    response.message.content
                ),
                "terraform_path":
                    terraform_path
            }

        # ----------------------------------------------------
        # Tool call
        # ----------------------------------------------------

        tool_call = (
            response.message.tool_calls[0]
        )

        tool_name = (
            tool_call.function.name
        )

        arguments = (
            tool_call.function.arguments
        )

        # ----------------------------------------------------
        # Terraform path required
        # ----------------------------------------------------

        if not terraform_path:

            return {
                "status": "path_required",

                "message": (
                    "I don't have a Terraform "
                    "working directory yet.\n\n"
                    "Please provide the path to "
                    "your Terraform project."
                )
            }

        # ----------------------------------------------------
        # Execute tool
        # ----------------------------------------------------

        result = execute_tool(

            tool_name,

            arguments,

            terraform_path
        )

        return {

            "status": result.get(
                "status",
                "success"
            ),

            "tool": tool_name,

            "terraform_path":
                terraform_path,

            "result": result
        }
