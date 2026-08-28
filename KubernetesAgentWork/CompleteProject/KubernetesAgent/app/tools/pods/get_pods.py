from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def get_pods(namespace: str = "default"):
    """
    List pods in a Kubernetes namespace.
    """

    result = run_kubectl(
        [
            "get",
            "pods",
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    if not result["stdout"]:
        return {
            "status": "success",
            "resource": "pods",
            "columns": [],
            "data": []
        }

    columns, data = parse_table(
        result["stdout"]
    )

    return {
        "status": "success",
        "resource": "pods",
        "namespace": namespace,
        "columns": columns,
        "data": data
    }
