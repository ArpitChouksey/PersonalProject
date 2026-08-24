def is_safe_to_execute(tool):
    """
    Return True when a tool can execute without confirmation.
    """

    return tool["risk"] == "read"


def requires_confirmation(tool):
    """
    Write and destructive operations require confirmation.
    """

    return tool["risk"] in [
        "write",
        "destructive"
    ]


def confirmation_message(tool_name, risk):
    """
    Generate an appropriate confirmation message.
    """

    if risk == "write":

        return (
            f"\nTool '{tool_name}' performs a WRITE operation.\n"
            "Do you want to continue? (yes/no): "
        )

    if risk == "destructive":

        return (
            f"\nWARNING: Tool '{tool_name}' performs a "
            "DESTRUCTIVE operation.\n"
            "This operation may modify or delete resources.\n"
            "Do you want to continue? (yes/no): "
        )

    return ""
