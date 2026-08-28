from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def delete_deployment(
    name: str,
    namespace: str = "default"
):
    """
    Delete a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "delete",
            "deployment",
            name,
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "title": "Kubernetes Deployment",
            "table": [],
            "rows": [],
            "summary": result["stderr"],
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "deployment",
        "name": name,
        "namespace": namespace,
        "title": "Kubernetes Deployment",
        "table": [
            "Deployment",
            "Namespace",
            "Status"
        ],
        "rows": [
            [
                name,
                namespace,
                "Deleted"
            ]
        ],
        "summary": (
            f"Deployment '{name}' deleted successfully."
        )
    }


delete_deployment.tool_name = "delete_deployment"

delete_deployment.tool_description = """
Delete a Kubernetes deployment.

Arguments:

- name: Deployment name
- namespace: Kubernetes namespace
"""
