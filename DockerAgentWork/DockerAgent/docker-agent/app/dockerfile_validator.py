import os
import subprocess


# ============================================================
# COMMAND EXECUTOR
# ============================================================

def run_command(command):
    """
    Execute a Linux/Docker CLI command.
    """

    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True
        )

        return {
            "command": command,
            "exit_code": result.returncode,
            "output": result.stdout.strip(),
            "error": result.stderr.strip()
        }

    except Exception as error:
        return {
            "command": command,
            "exit_code": 1,
            "output": "",
            "error": str(error)
        }


# ============================================================
# VALIDATE DOCKERFILE
# ============================================================

def validate_dockerfile(dockerfile_path):
    """
    Validate a Dockerfile using Docker CLI and Linux commands.

    Python only orchestrates the commands.
    """

    # --------------------------------------------------------
    # Check Dockerfile exists
    # --------------------------------------------------------

    if not os.path.isfile(dockerfile_path):
        return {
            "exit_code": 1,
            "error": f"Dockerfile not found: {dockerfile_path}"
        }

    absolute_path = os.path.abspath(
        dockerfile_path
    )

    build_context = os.path.dirname(
        absolute_path
    )

    results = []

    # --------------------------------------------------------
    # 1. Dockerfile syntax / build checks
    # --------------------------------------------------------

    results.append(
        run_command(
            f"docker build "
            f"--check "
            f"-f '{absolute_path}' "
            f"'{build_context}'"
        )
    )

    # --------------------------------------------------------
    # 2. FROM instruction
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^FROM[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 3. Check latest tag
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^FROM[[:space:]].*:latest([[:space:]]|$)' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 4. Check USER instruction
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^USER[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 5. Check ADD instruction
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^ADD[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 6. Check HEALTHCHECK
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^HEALTHCHECK[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 7. Check EXPOSE
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^EXPOSE[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 8. Check possible secrets
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -niE "
            f"'password|passwd|secret|token|api[_-]?key|access[_-]?key' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 9. Check package installation
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -niE "
            f"'apt-get install|apt install|apk add|yum install|dnf install' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 10. Check APT cache cleanup
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -niE "
            f"'rm -rf /var/lib/apt/lists|apt-get clean' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 11. Check multi-stage build
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -cE '^FROM[[:space:] ]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 12. Check .dockerignore
    # --------------------------------------------------------

    dockerignore_path = os.path.join(
        build_context,
        ".dockerignore"
    )

    results.append(
        run_command(
            f"test -f '{dockerignore_path}'"
        )
    )

    # --------------------------------------------------------
    # 13. Check COPY
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^COPY[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 14. Check ARG
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^ARG[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # 15. Check ENV
    # --------------------------------------------------------

    results.append(
        run_command(
            f"grep -nE '^ENV[[:space:]]+' "
            f"'{absolute_path}'"
        )
    )

    # --------------------------------------------------------
    # Build final result
    # --------------------------------------------------------

    return {
        "exit_code": 0,
        "dockerfile": absolute_path,
        "build_context": build_context,
        "results": results
    }
