import os
import subprocess
import yaml


def _run(command, cwd=None):

    try:

        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            cwd=cwd
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


def generate_compose(
    output_path,
    services_yaml
):

    try:

        services = yaml.safe_load(
            services_yaml
        )

        if not isinstance(
            services,
            dict
        ):

            return {
                "return_code": 1,
                "error": (
                    "services_yaml must contain "
                    "a YAML object."
                )
            }

        compose = {
            "services": services
        }

        directory = os.path.dirname(
            os.path.abspath(
                output_path
            )
        )

        os.makedirs(
            directory,
            exist_ok=True
        )

        with open(
            output_path,
            "w",
            encoding="utf-8"
        ) as file:

            yaml.safe_dump(
                compose,
                file,
                sort_keys=False
            )

        return {
            "return_code": 0,
            "stdout": (
                f"Compose file created: "
                f"{output_path}"
            ),
            "stderr": "",
            "command": []
        }

    except Exception as error:

        return {
            "return_code": 1,
            "error": str(error)
        }


def docker_compose_config(
    compose_file="compose.yaml"
):

    return _run([
        "docker",
        "compose",
        "-f",
        compose_file,
        "config"
    ])


def docker_compose_ps(
    compose_file="compose.yaml"
):

    return _run([
        "docker",
        "compose",
        "-f",
        compose_file,
        "ps"
    ])


def docker_compose_up(
    compose_file="compose.yaml"
):

    return _run([
        "docker",
        "compose",
        "-f",
        compose_file,
        "up",
        "-d"
    ])


def docker_compose_down(
    compose_file="compose.yaml"
):

    return _run([
        "docker",
        "compose",
        "-f",
        compose_file,
        "down"
    ])
