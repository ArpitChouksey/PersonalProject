from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_rolebindings(namespace: str = "default"):
    """
    List RoleBindings in a namespace.
    """

    result = run_kubectl(
        [
            "get",
            "rolebindings",
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
        "resource": "rolebindings",
        "columns": columns,
        "data": data
    }
