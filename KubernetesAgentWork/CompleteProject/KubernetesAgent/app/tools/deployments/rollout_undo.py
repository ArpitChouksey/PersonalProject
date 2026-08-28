from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def rollout_undo(
    name: str,
    namespace: str = "default"
):
    """
    Roll back a Kubernetes deployment to its previous revision.
    """

    result = run_kubectl(
        [
            "rollout",
            "undo",
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
        "resource": "deployment-rollout",
        "output": result["stdout"]
    }
