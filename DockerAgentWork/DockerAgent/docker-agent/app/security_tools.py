import subprocess
import os


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


def image_security_check(image):
    """
    Perform Docker CLI based security checks.

    If Trivy is installed, also run Trivy.
    """

    inspect = _run([
        "docker",
        "inspect",
        image
    ])

    if inspect["return_code"] != 0:
        return inspect

    recommendations = []

    user_result = _run([
        "docker",
        "inspect",
        "--format",
        "{{.Config.User}}",
        image
    ])

    user = user_result["stdout"]

    if not user:
        recommendations.append(
            "Container does not specify a non-root USER."
        )

    privileged_result = _run([
        "docker",
        "inspect",
        "--format",
        "{{.HostConfig.Privileged}}",
        image
    ])

    recommendations.append(
        "Run containers with --privileged=false."
    )

    result = {
        "return_code": 0,
        "image": image,
        "user": user,
        "privileged_recommendation": (
            "Avoid privileged containers."
        ),
        "recommendations": recommendations
    }

    trivy_check = subprocess.run(
        ["bash", "-lc", "command -v trivy"],
        capture_output=True,
        text=True
    )

    if trivy_check.returncode == 0:

        trivy = _run([
            "trivy",
            "image",
            "--severity",
            "HIGH,CRITICAL",
            image
        ])

        result["trivy"] = trivy

    else:

        result["trivy"] = {
            "status": "NOT_INSTALLED",
            "recommendation": (
                "Install Trivy to perform vulnerability scanning."
            )
        }

    return result


def dockerfile_security_recommendations(
    dockerfile_path
):

    if not os.path.isfile(
        dockerfile_path
    ):

        return {
            "return_code": 1,
            "error": (
                f"Dockerfile not found: "
                f"{dockerfile_path}"
            )
        }

    with open(
        dockerfile_path,
        "r",
        encoding="utf-8"
    ) as file:

        lines = file.readlines()

    findings = []

    content = "".join(
        lines
    )

    if "USER " not in content:
        findings.append(
            "Add a non-root USER instruction."
        )

    if "latest" in content:
        findings.append(
            "Avoid using mutable :latest image tags."
        )

    if "ADD " in content:
        findings.append(
            "Prefer COPY over ADD unless ADD features are required."
        )

    if "--privileged" in content:
        findings.append(
            "Avoid privileged execution."
        )

    if "curl" in content and (
        "curl | sh" in content
        or "curl|sh" in content
    ):
        findings.append(
            "Avoid piping remote scripts directly into a shell."
        )

    if not findings:

        findings.append(
            "No basic security issues detected."
        )

    return {
        "return_code": 0,
        "dockerfile": dockerfile_path,
        "findings": findings
    }
