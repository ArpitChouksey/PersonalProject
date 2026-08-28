from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_services(namespace: str = "default"):
    """
    List Kubernetes services.
    """

    result = run_kubectl(
        [
            "get",
            "services",
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
        "resource": "services",
        "columns": columns,
        "data": data
    }
