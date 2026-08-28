from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def delete_namespace(name: str):
    """
    Delete a Kubernetes namespace.
    """

    result = run_kubectl(
        ["delete", "namespace", name]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "namespace",
        "output": result["stdout"]
    }
