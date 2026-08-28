from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def rollout_restart(
    name: str,
    namespace: str = "default"
):
    """
    Restart all pods managed by a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "rollout",
            "restart",
            f"deployment/{name}",
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
        "resource": "deployment",
        "output": result["stdout"]
    }
