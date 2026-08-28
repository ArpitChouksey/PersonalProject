from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def create_namespace(name: str):
    """
    Create a Kubernetes namespace.
    """

    result = run_kubectl(
        ["create", "namespace", name]
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"],
            "title": "Kubernetes Namespace",
            "table": [],
            "rows": [],
            "summary": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "namespace",
        "name": name,
        "title": "Kubernetes Namespace",
        "table": ["Name", "Status"],
        "rows": [
            [name, "Active"]
        ],
        "summary": f"Namespace '{name}' created successfully."
    }
