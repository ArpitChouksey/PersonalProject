from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def create_secret(
    name: str,
    key: str,
    value: str,
    namespace: str = "default"
):
    """
    Create a Kubernetes opaque Secret from a key-value pair.
    """

    result = run_kubectl(
        [
            "create",
            "secret",
            "generic",
            name,
            f"--from-literal={key}={value}",
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
        "resource": "secret",
        "output": result["stdout"]
    }
