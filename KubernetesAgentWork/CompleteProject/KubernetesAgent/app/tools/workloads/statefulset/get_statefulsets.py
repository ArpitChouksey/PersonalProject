from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_statefulsets(namespace: str = "default"):
    """
    List Kubernetes StatefulSets.
    """

    result = run_kubectl(
        [
            "get",
            "statefulsets",
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
        "resource": "statefulsets",
        "columns": columns,
        "data": data
    }
