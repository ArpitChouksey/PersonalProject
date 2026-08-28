from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_resource_quota(namespace: str = "default"):
    """
    List ResourceQuotas in a namespace.
    """

    result = run_kubectl(
        [
            "get",
            "resourcequota",
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
        "resource": "resourcequota",
        "columns": columns,
        "data": data
    }
