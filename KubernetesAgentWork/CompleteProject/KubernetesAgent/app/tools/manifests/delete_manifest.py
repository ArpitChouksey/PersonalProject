from pathlib import Path

from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def delete_manifest(path: str):
    """
    Delete Kubernetes resources defined in a local YAML manifest.
    """

    file_path = Path(path).expanduser()

    if not file_path.is_file():
        return {
            "status": "error",
            "message": f"File not found: {path}"
        }

    result = run_kubectl(
        [
            "delete",
            "-f",
            str(file_path)
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "manifest",
        "output": result["stdout"]
    }
