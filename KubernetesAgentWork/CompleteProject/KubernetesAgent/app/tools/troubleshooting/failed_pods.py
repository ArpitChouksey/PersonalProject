from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def failed_pods(namespace: str = "default"):
    """
    Find pods whose phase is Failed.
    """

    result = run_kubectl(
        [
            "get",
            "pods",
            "-n",
            namespace,
            "--field-selector=status.phase=Failed"
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "failed-pods",
        "output": result["stdout"]
    }
