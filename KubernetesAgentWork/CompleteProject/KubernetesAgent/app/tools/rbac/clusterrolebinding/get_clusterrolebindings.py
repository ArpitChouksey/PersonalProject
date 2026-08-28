from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_clusterrolebindings():
    """
    List Kubernetes ClusterRoleBindings.
    """

    result = run_kubectl(
        ["get", "clusterrolebindings"]
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
        "resource": "clusterrolebindings",
        "columns": columns,
        "data": data
    }
