from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_hpa(namespace: str = "default"):
    """
    List Horizontal Pod Autoscalers.
    """

    result = run_kubectl(
        [
            "get",
            "hpa",
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
        "resource": "hpa",
        "columns": columns,
        "data": data
    }
