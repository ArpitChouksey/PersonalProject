from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def restart_pod(
    pod_name: str,
    namespace: str = "default"
):
    """
    Restart a pod by deleting it so its controller can recreate it.
    """

    result = run_kubectl(
        [
            "delete",
            "pod",
            pod_name,
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "pod",
        "output": result["stdout"]
    }
