from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def get_cluster_info():
    """
    Show Kubernetes cluster information.
    """

    result = run_kubectl(
        ["cluster-info"]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "cluster",
        "output": result["stdout"]
    }
