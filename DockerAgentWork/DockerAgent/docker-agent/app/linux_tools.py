import subprocess
from typing import Any


def _run_command(command: list[str]) -> dict[str, Any]:
    """
    Execute a Linux command safely and return a standard result.
    """

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=30,
        )

        return {
            "status": "SUCCESS" if result.returncode == 0 else "ERROR",
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
            "stderr": "Command timed out",
            "command": command,
        }

    except FileNotFoundError:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": f"Command not found: {command[0]}",
            "command": command,
        }

    except Exception as exc:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": str(exc),
            "command": command,
        }


def process_list() -> dict[str, Any]:
    """
    List running processes.

    Uses ps when available.
    """

    command = [
        "ps",
        "aux",
    ]

    result = _run_command(command)

    if result["status"] != "SUCCESS":
        return result

    lines = result["stdout"].splitlines()

    if not lines:
        result["data"] = []
        return result

    processes = []

    for line in lines[1:]:
        parts = line.split(None, 10)

        if len(parts) < 11:
            continue

        processes.append(
            {
                "user": parts[0],
                "pid": parts[1],
                "cpu": parts[2],
                "memory": parts[3],
                "vsz": parts[4],
                "rss": parts[5],
                "tty": parts[6],
                "stat": parts[7],
                "start": parts[8],
                "time": parts[9],
                "command": parts[10],
            }
        )

    result["data"] = processes

    return result


def disk_usage() -> dict[str, Any]:
    """
    Show filesystem disk usage.
    """

    command = [
        "df",
        "-h",
    ]

    result = _run_command(command)

    if result["status"] != "SUCCESS":
        return result

    lines = result["stdout"].splitlines()

    if not lines:
        result["data"] = []
        return result

    usage = []

    for line in lines[1:]:
        parts = line.split()

        if len(parts) < 6:
            continue

        usage.append(
            {
                "filesystem": parts[0],
                "size": parts[1],
                "used": parts[2],
                "available": parts[3],
                "use_percent": parts[4],
                "mounted_on": parts[5],
            }
        )

    result["data"] = usage

    return result


def memory_usage() -> dict[str, Any]:
    """
    Show memory information.
    """

    command = [
        "free",
        "-h",
    ]

    return _run_command(command)


def get_linux_tools():
    """
    Central Linux tool registry.
    """

    return {
        "process_list": process_list,
        "disk_usage": disk_usage,
        "memory_usage": memory_usage,
    }
