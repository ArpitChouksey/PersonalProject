from app.tool_registry import (
    list_tools,
    execute_tool,
)

from app.llm_agent import (
    create_llm_agent,
)


# =============================================================
# DISPLAY TOOL INFORMATION
# =============================================================

def display_tools():

    tools = list_tools()

    print()
    print("=" * 60)
    print("Available Tools")
    print("=" * 60)

    for tool in tools:

        print()
        print(
            f"Tool: {tool['name']}"
        )

        print(
            f"Description: {tool.get('description', '')}"
        )

        print(
            f"Risk: {tool.get('risk', 'read')}"
        )

        parameters = tool.get(
            "parameters",
            {}
        )

        if not parameters:

            print(
                "Parameters: None"
            )

        else:

            print(
                "Parameters:"
            )

            for name, info in parameters.items():

                if isinstance(info, dict):

                    parameter_type = info.get(
                        "type",
                        "string"
                    )

                    description = info.get(
                        "description",
                        ""
                    )

                else:

                    parameter_type = "string"
                    description = ""

                print(
                    f"  - {name} "
                    f"({parameter_type}): "
                    f"{description}"
                )

    print()
    print("=" * 60)


# =============================================================
# TOOL MODE
# =============================================================

def tool_mode():

    while True:

        print()
        print("-" * 60)

        tool_name = input(
            "Enter tool name or 'exit': "
        ).strip()

        if tool_name.lower() == "exit":

            return

        if not tool_name:

            print(
                "Please enter a tool name."
            )

            continue

        tools = list_tools()

        selected_tool = None

        for tool in tools:

            if tool["name"] == tool_name:

                selected_tool = tool
                break

        if selected_tool is None:

            print()
            print(
                f"Unknown tool: {tool_name}"
            )

            continue

        parameters = selected_tool.get(
            "parameters",
            {}
        )

        arguments = {}

        # -----------------------------------------------------
        # COLLECT PARAMETERS
        # -----------------------------------------------------

        for parameter_name, parameter_info in parameters.items():

            if isinstance(parameter_info, dict):

                parameter_type = parameter_info.get(
                    "type",
                    "string"
                )

                description = parameter_info.get(
                    "description",
                    ""
                )

            else:

                parameter_type = "string"
                description = ""

            print()

            if description:

                print(
                    description
                )

            value = input(
                f"Enter {parameter_name} "
                f"({parameter_type}): "
            ).strip()

            # Integer conversion
            if parameter_type == "integer":

                try:

                    value = int(value)

                except ValueError:

                    print(
                        "Invalid integer value."
                    )

                    continue

            # Boolean conversion
            elif parameter_type == "boolean":

                value = value.lower() in (
                    "true",
                    "yes",
                    "1"
                )

            arguments[parameter_name] = value

        # -----------------------------------------------------
        # SAFETY CHECK
        # -----------------------------------------------------

        risk = selected_tool.get(
            "risk",
            "read"
        ).lower()

        if risk == "write":

            print()
            print(
                "Tool performs a WRITE operation."
            )

            answer = input(
                "Do you want to continue? (yes/no): "
            ).strip().lower()

            if answer not in (
                "yes",
                "y"
            ):

                print(
                    "Operation cancelled."
                )

                continue

        # -----------------------------------------------------
        # EXECUTE
        # -----------------------------------------------------

        print()
        print(
            f"Executing tool: {tool_name}"
        )

        result = execute_tool(
            tool_name,
            arguments
        )

        print()
        print("=" * 60)
        print("Tool Result")
        print("=" * 60)

        print(result)


# =============================================================
# NATURAL LANGUAGE MODE
# =============================================================

def natural_language_mode():

    agent = create_llm_agent()

    print()
    print("=" * 60)
    print("Docker Agent - Natural Language Mode")
    print("=" * 60)

    print()
    print("Examples:")
    print()
    print(
        "  Show me all Docker containers"
    )

    print(
        "  Show me the logs of activemq"
    )

    print(
        "  How much disk space is available?"
    )

    print(
        "  Restart activemq"
    )

    print(
        "  Diagnose kafka"
    )

    print()
    print(
        "Type 'exit' to return."
    )

    while True:

        print()

        try:

            user_message = input(
                "You: "
            ).strip()

        except (
            EOFError,
            KeyboardInterrupt
        ):

            print()

            return

        if user_message.lower() == "exit":

            return

        if not user_message:

            continue

        print()
        print(
            "Agent is analyzing..."
        )

        result = agent.ask(
            user_message
        )

        print()
        print("=" * 60)
        print("Agent")
        print("=" * 60)

        if result.get(
            "status"
        ) == "SUCCESS":

            print(
                result.get(
                    "response",
                    ""
                )
            )

        else:

            print(
                "Agent Error:"
            )

            print(
                result.get(
                    "message",
                    result
                )
            )


# =============================================================
# MAIN
# =============================================================

def main():

    while True:

        print()
        print("=" * 60)
        print("Docker Agent - Phase 12")
        print("=" * 60)

        print()
        print("1. Tool Mode")
        print("2. Natural Language Agent Mode")
        print("3. Exit")

        print()

        choice = input(
            "Choose option: "
        ).strip()

        if choice == "1":

            display_tools()
            tool_mode()

        elif choice == "2":

            natural_language_mode()

        elif choice == "3":

            print()
            print(
                "Exiting Docker Agent..."
            )

            break

        else:

            print()
            print(
                "Invalid option."
            )


if __name__ == "__main__":
    main()
