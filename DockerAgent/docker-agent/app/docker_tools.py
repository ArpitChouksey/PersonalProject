import subprocess
from typing import Any


def _run_docker_command(command: list[str]) -> dict[str, Any]:
    """
    Execute a Docker CLI command and return a standard result.
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
            "stderr": "Docker command timed out",
            "command": command,
        }

    except FileNotFoundError:
        return {
            "status": "ERROR",
            "return_code": -1,
            "stdout": "",
            "stderr": "Docker CLI not found",
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


def docker_ps() -> dict[str, Any]:
    """
    List all Docker containers.

    Uses docker ps -a so the agent has complete container information.
    """

    command = [
        "docker",
        "ps",
        "-a",
        "--format",
        "{{.ID}}|{{.Image}}|{{.Command}}|{{.CreatedAt}}|{{.Status}}|{{.Ports}}|{{.Names}}",
    ]

    result = _run_docker_command(command)

    if result["status"] != "SUCCESS":
        return result

    containers = []

    for line in result["stdout"].splitlines():
        if not line.strip():
            continue

        parts = line.split("|", 6)

        if len(parts) != 7:
            continue

        containers.append(
            {
                "id": parts[0],
                "image": parts[1],
                "command": parts[2],
                "created": parts[3],
                "status": parts[4],
                "ports": parts[5],
                "name": parts[6],
            }
        )

    result["data"] = containers

    return result


def docker_images() -> dict[str, Any]:
    """
    List Docker images available locally.
    """

    command = [
        "docker",
        "images",
        "--format",
        "{{.Repository}}|{{.Tag}}|{{.ID}}|{{.CreatedSince}}|{{.Size}}",
    ]

    result = _run_docker_command(command)

    if result["status"] != "SUCCESS":
        return result

    images = []

    for line in result["stdout"].splitlines():
        if not line.strip():
            continue

        parts = line.split("|", 4)

        if len(parts) != 5:
            continue

        images.append(
            {
                "repository": parts[0],
                "tag": parts[1],
                "image_id": parts[2],
                "created": parts[3],
                "size": parts[4],
            }
        )

    result["data"] = images

    return result


def docker_container_inspect(name: str) -> dict[str, Any]:
    """
    Inspect a specific Docker container.
    """

    command = [
        "docker",
        "inspect",
        name,
    ]

    return _run_docker_command(command)


def docker_container_logs(
    name: str,
    tail: int = 100,
) -> dict[str, Any]:
    """
    Fetch logs from a Docker container.
    """

    command = [
        "docker",
        "logs",
        "--tail",
        str(tail),
        name,
    ]

    return _run_docker_command(command)


def get_docker_tools():
    """
    Central Docker tool registry.
    """

    return {
        "docker_ps": docker_ps,
        "docker_images": docker_images,
        "docker_container_inspect": docker_container_inspect,
        "docker_container_logs": docker_container_logs,
    }
