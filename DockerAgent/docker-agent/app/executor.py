from typing import Any
import subprocess


# ============================================================
# APPROVAL EXCEPTION
# ============================================================

class ApprovalRequired(Exception):
    """
    Raised when a write operation requires approval.
    """

    def __init__(
        self,
        tool_name: str,
        parameters: dict[str, Any],
        message: str,
    ):
        self.tool_name = tool_name
        self.parameters = parameters
        self.message = message

        super().__init__(message)


# ============================================================
# COMMAND EXECUTOR
# ============================================================

def run_command(
    command: list[str],
    timeout: int = 120,
) -> dict[str, Any]:
    """
    Execute a system command.
    """

    if not command:
        return {
            "status": "ERROR",
            "return_code": 1,
            "stdout": "",
            "stderr": "Command cannot be empty.",
            "command": [],
        }

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )

        return {
            "status": (
                "SUCCESS"
                if result.returncode == 0
                else "ERROR"
            ),
            "return_code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "command": command,
        }

    except subprocess.TimeoutExpired:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": (
                f"Command timed out after "
                f"{timeout} seconds."
            ),
            "command": command,
        }

    except FileNotFoundError:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": (
                f"Command not found: {command[0]}"
            ),
            "command": command,
        }

    except PermissionError as error:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": f"Permission denied: {error}",
            "command": command,
        }

    except Exception as error:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": str(error),
            "command": command,
        }


# ============================================================
# TOOL APPROVAL
# ============================================================

def requires_approval(
    tool_name: str,
    tool_registry: dict,
) -> bool:
    """
    Check whether a registered tool is a write operation.
    """

    tool = tool_registry.get(tool_name)

    if not tool:
        return False

    return tool.get("risk", "read") == "write"


# ============================================================
# EXECUTE READ TOOL
# ============================================================

def execute_read_tool(
    tool_name: str,
    parameters: dict[str, Any],
    tool_registry: dict,
):
    """
    Execute a read-only registered tool.
    """

    tool = tool_registry.get(tool_name)

    if not tool:
        return {
            "status": "ERROR",
            "message": (
                f"Unknown tool: {tool_name}"
            ),
        }

    function = tool.get("function")

    if not function:
        return {
            "status": "ERROR",
            "message": (
                f"Tool has no executable function: "
                f"{tool_name}"
            ),
        }

    try:
        return function(
            **parameters
        )

    except TypeError as error:
        return {
            "status": "ERROR",
            "message": (
                f"Invalid parameters for "
                f"{tool_name}: {error}"
            ),
        }

    except Exception as error:
        return {
            "status": "ERROR",
            "message": str(error),
        }


# ============================================================
# EXECUTE APPROVED TOOL
# ============================================================

def execute_approved_tool(
    tool_name: str,
    parameters: dict[str, Any],
    tool_registry: dict,
):
    """
    Execute a tool after UI approval.

    No approval is requested here because approval
    has already been given by the user.
    """

    tool = tool_registry.get(tool_name)

    if not tool:
        return {
            "status": "ERROR",
            "message": (
                f"Unknown tool: {tool_name}"
            ),
        }

    function = tool.get("function")

    if not function:
        return {
            "status": "ERROR",
            "message": (
                f"Tool has no executable function: "
                f"{tool_name}"
            ),
        }

    try:
        return function(
            **parameters
        )

    except TypeError as error:
        return {
            "status": "ERROR",
            "message": (
                f"Invalid parameters for "
                f"{tool_name}: {error}"
            ),
        }

    except Exception as error:
        return {
            "status": "ERROR",
            "message": str(error),
        }


# ============================================================
# EXECUTE TOOL WITH APPROVAL CHECK
# ============================================================

def execute_tool(
    tool_name: str,
    parameters: dict[str, Any],
    tool_registry: dict,
):
    """
    Execute a tool.

    Read operation:
        execute immediately.

    Write operation:
        raise ApprovalRequired so FastAPI can
        send the approval request to React UI.
    """

    if parameters is None:
        parameters = {}

    tool = tool_registry.get(tool_name)

    if not tool:
        return {
            "status": "ERROR",
            "message": (
                f"Unknown tool: {tool_name}"
            ),
        }

    # --------------------------------------------------------
    # WRITE OPERATION
    # --------------------------------------------------------

    if requires_approval(
        tool_name,
        tool_registry,
    ):

        raise ApprovalRequired(
            tool_name=tool_name,
            parameters=parameters,
            message=(
                "This operation will modify "
                "Docker/Linux state and requires "
                "your approval."
            ),
        )

    # --------------------------------------------------------
    # READ OPERATION
    # --------------------------------------------------------

    return execute_read_tool(
        tool_name,
        parameters,
        tool_registry,
    )
