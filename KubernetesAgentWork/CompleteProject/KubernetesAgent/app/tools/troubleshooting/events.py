from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import (
    run_kubectl,
    parse_table
)


@kubernetes_tool
def events(namespace: str = "default"):
    """
    Show Kubernetes events in a namespace.
    """

    result = run_kubectl(
        [
            "get",
            "events",
            "--sort-by=.lastTimestamp",
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
        "resource": "events",
        "columns": columns,
        "data": data
    }
