from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def get_resource_yaml(
    resource: str,
    name: str,
    namespace: str = "default"
):
    """
    Return the YAML representation of a Kubernetes resource.
    """

    result = run_kubectl(
        [
            "get",
            resource,
            name,
            "-n",
            namespace,
            "-o",
            "yaml"
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": resource,
        "name": name,
        "output": result["stdout"]
    }
