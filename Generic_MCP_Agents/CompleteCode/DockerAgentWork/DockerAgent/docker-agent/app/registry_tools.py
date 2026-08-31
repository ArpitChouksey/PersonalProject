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


def docker_login_status():
    """
    Check whether Docker can access its local credential configuration.
    """

    result = _run([
        "docker",
        "info"
    ])

    if result["return_code"] != 0:
        return result

    return {
        "return_code": 0,
        "stdout": "Docker daemon is available.",
        "stderr": "",
        "command": ["docker", "info"]
    }


def docker_tag(image, target):
    """
    Tag an existing Docker image.
    """

    return _run([
        "docker",
        "tag",
        image,
        target
    ])


def docker_push(image):
    """
    Push an image to its configured registry.
    """

    return _run([
        "docker",
        "push",
        image
    ])


def docker_pull(image):
    """
    Pull an image from a registry.
    """

    return _run([
        "docker",
        "pull",
        image
    ])


def docker_registry_check(image):
    """
    Check whether an image reference appears to contain a registry.
    """

    if "/" not in image:
        return {
            "return_code": 0,
            "stdout": (
                f"{image} appears to be a Docker Hub/local image "
                "reference."
            ),
            "stderr": "",
            "command": []
        }

    first_part = image.split("/")[0]

    registry_indicators = [
        ".",
        ":",
        "localhost"
    ]

    has_registry = (
        any(
            item in first_part
            for item in registry_indicators
        )
    )

    if has_registry:
        message = f"Registry detected: {first_part}"
    else:
        message = (
            f"No explicit private registry detected. "
            f"Reference may use Docker Hub: {image}"
        )

    return {
        "return_code": 0,
        "stdout": message,
        "stderr": "",
        "command": []
    }
