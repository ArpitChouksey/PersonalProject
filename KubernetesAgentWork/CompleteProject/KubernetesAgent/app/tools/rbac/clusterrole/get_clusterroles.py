from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_clusterroles():
    """
    List Kubernetes ClusterRoles.
    """

    result = run_kubectl(
        ["get", "clusterroles"]
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
        "resource": "clusterroles",
        "columns": columns,
        "data": data
    }
