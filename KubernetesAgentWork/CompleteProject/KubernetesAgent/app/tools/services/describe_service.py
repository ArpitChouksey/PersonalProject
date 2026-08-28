from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def describe_service(
    name: str,
    namespace: str = "default"
):
    """
    Show detailed information about a Kubernetes service.
    """

    result = run_kubectl(
        [
            "describe",
            "service",
            name,
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
        "resource": "service",
        "output": result["stdout"]
    }
