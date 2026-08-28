from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_roles(namespace: str = "default"):
    """
    List Roles in a Kubernetes namespace.
    """

    result = run_kubectl(
        [
            "get",
            "roles",
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
        "resource": "roles",
        "columns": columns,
        "data": data
    }
