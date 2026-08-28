from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def list_namespaces():
    """
    List all Kubernetes namespaces.
    """

    result = run_kubectl(
        ["get", "namespaces"]
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
        "resource": "namespaces",
        "columns": columns,
        "data": data
    }
