from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def describe_pod(
    pod_name: str,
    namespace: str = "default"
):
    """
    Show detailed information and events for a pod.
    """

    result = run_kubectl(
        [
            "describe",
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
        "pod": pod_name,
        "output": result["stdout"]
    }
