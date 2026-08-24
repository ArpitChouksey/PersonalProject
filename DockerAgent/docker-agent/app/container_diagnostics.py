import json
import subprocess


def _run(command):
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )

        return {
            "return_code": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "command": command
        }

    except Exception as error:
        return {
            "return_code": 1,
            "stdout": "",
            "stderr": str(error),
            "command": command
        }


def container_exit_code(container):
    """
    Show container state, exit code and restart count.
    """

    result = _run([
        "docker",
        "inspect",
        "--format",
        (
            "Status={{.State.Status}}\n"
            "Running={{.State.Running}}\n"
            "ExitCode={{.State.ExitCode}}\n"
            "OOMKilled={{.State.OOMKilled}}\n"
            "RestartCount={{.RestartCount}}\n"
            "Error={{.State.Error}}"
        ),
        container
    ])

    return result


def container_diagnose(container):
    """
    Collect basic diagnostic information for a container.
    """

    inspect = _run([
        "docker",
        "inspect",
        container
    ])

    if inspect["return_code"] != 0:
        return inspect

    logs = _run([
        "docker",
        "logs",
        "--tail",
        "100",
        container
    ])

    stats = _run([
        "docker",
        "stats",
        "--no-stream",
        container
    ])

    state = _run([
        "docker",
        "inspect",
        "--format",
        (
            "Status={{.State.Status}}\n"
            "Running={{.State.Running}}\n"
            "ExitCode={{.State.ExitCode}}\n"
            "OOMKilled={{.State.OOMKilled}}\n"
            "RestartCount={{.RestartCount}}\n"
            "Error={{.State.Error}}"
        ),
        container
    ])

    return {
        "return_code": 0,
        "container": container,
        "state": state,
        "stats": stats,
        "logs": logs
    }


def container_health(container):
    """
    Check Docker health status.
    """

    return _run([
        "docker",
        "inspect",
        "--format",
        (
            "{{if .State.Health}}"
            "Status={{.State.Health.Status}}\n"
            "FailingStreak={{.State.Health.FailingStreak}}"
            "{{else}}"
            "Healthcheck=NOT_CONFIGURED"
            "{{end}}"
        ),
        container
    ])
