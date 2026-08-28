from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_configmaps(namespace: str = "default"):
    """
    List ConfigMaps in a Kubernetes namespace.
    """

    result = run_kubectl(
        [
            "get",
            "configmaps",
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    columns, data = parse_table(
        result["stdout"]
    )

    return {
        "status": "success",
        "resource": "configmaps",
        "columns": columns,
        "data": data
    }
