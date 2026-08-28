from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_secrets(namespace: str = "default"):
    """
    List Kubernetes Secrets without exposing secret values.
    """

    result = run_kubectl(
        [
            "get",
            "secrets",
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
        "resource": "secrets",
        "columns": columns,
        "data": data
    }
