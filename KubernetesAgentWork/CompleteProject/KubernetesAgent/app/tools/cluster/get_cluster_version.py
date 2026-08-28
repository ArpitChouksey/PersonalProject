
from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def get_cluster_version():
    """
    Show Kubernetes client and server versions.
    """

    result = run_kubectl(
        ["version"]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "cluster-version",
        "output": result["stdout"]
    }
