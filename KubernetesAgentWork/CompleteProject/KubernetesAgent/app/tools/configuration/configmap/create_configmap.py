from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def create_configmap(
    name: str,
    key: str,
    value: str,
    namespace: str = "default"
):
    """
    Create a ConfigMap containing one key-value pair.
    """

    result = run_kubectl(
        [
            "create",
            "configmap",
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
        "resource": "configmap",
        "output": result["stdout"]
    }
