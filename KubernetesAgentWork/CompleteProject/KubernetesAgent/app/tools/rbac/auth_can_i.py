from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def auth_can_i(
    verb: str,
    resource: str,
    namespace: str = "default"
):
    """
    Check whether the current Kubernetes identity can perform an action.
    """

    result = run_kubectl(
        [
            "auth",
            "can-i",
            verb,
            resource,
            "-n",
            namespace
        ]
    )

    return {
        "status": "success"
        if result["success"]
        else "error",
        "resource": "authorization",
        "output": (
            result["stdout"]
            if result["success"]
            else result["stderr"]
        )
    }
