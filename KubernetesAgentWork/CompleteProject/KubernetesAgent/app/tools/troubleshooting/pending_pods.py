from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def pending_pods(namespace: str = "default"):
    """
    Find pods that are currently Pending.
    """

    result = run_kubectl(
        [
            "get",
            "pods",
            "-n",
            namespace,
            "--field-selector=status.phase=Pending"
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "pending-pods",
        "output": result["stdout"]
    }
