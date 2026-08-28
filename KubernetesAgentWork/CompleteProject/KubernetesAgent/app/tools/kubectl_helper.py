import json
import subprocess


def run_kubectl(
    args: list[str]
):
    """
    Execute kubectl safely as a subprocess.
    """

    command = ["kubectl"] + args

    try:

        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:

            return {
                "success": False,
                "stdout": result.stdout.strip(),
                "stderr": result.stderr.strip(),
                "returncode": result.returncode
            }

        return {
            "success": True,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "returncode": 0
        }

    except FileNotFoundError:

        return {
            "success": False,
            "stdout": "",
            "stderr": "kubectl was not found.",
            "returncode": -1
        }

    except Exception as exc:

        return {
            "success": False,
            "stdout": "",
            "stderr": str(exc),
            "returncode": -1
        }


def run_kubectl_json(args: list[str]):

    result = run_kubectl(
        args + ["-o", "json"]
    )

    if not result["success"]:
        return result

    try:

        result["json"] = json.loads(
            result["stdout"]
        )

        return result

    except json.JSONDecodeError:

        result["success"] = False
        result["stderr"] = (
            "kubectl returned invalid JSON."
        )

        return result


def parse_table(output: str):

    lines = [
        line.strip()
        for line in output.splitlines()
        if line.strip()
    ]

    if len(lines) < 2:
        return [], []

    headers = lines[0].split()

    rows = []

    for line in lines[1:]:

        values = line.split()

        row = {}

        for index, header in enumerate(headers):

            row[header] = (
                values[index]
                if index < len(values)
                else ""
            )

        rows.append(row)

    return headers, rows


def parse_yaml_resource(output: str):

    return {
        "status": "success",
        "output": output
    }
