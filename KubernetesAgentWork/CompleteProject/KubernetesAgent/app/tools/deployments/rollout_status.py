from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def rollout_status(
    name: str,
    namespace: str = "default"
):
    """
    Show rollout status for a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "rollout",
            "status",
            f"deployment/{name}",
            "-n",
            namespace
        ]
    )

    return {
        "status": "success"
        if result["success"]
        else "error",
        "resource": "deployment-rollout",
        "output": result["stdout"]
        if result["success"]
        else result["stderr"]
    }
