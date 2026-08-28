from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def scale_deployment(
    name: str,
    replicas: int,
    namespace: str = "default"
):
    """
    Scale a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "scale",
            "deployment",
            name,
            f"--replicas={replicas}",
            "-n",
            namespace
        ]
    )

    if not result["success"]:
        return {
            "status": "error",
            "title": "Kubernetes Deployment Scaling",
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
        "replicas": replicas,
        "title": "Kubernetes Deployment Scaling",
        "table": [
            "Deployment",
            "Namespace",
            "Replicas"
        ],
        "rows": [
            [
                name,
                namespace,
                replicas
            ]
        ],
        "summary": (
            f"Deployment '{name}' scaled to "
            f"{replicas} replica(s)."
        )
    }


scale_deployment.tool_name = "scale_deployment"

scale_deployment.tool_description = """
Scale a Kubernetes deployment.

Arguments:

- name: Deployment name
- replicas: Desired replica count
- namespace: Kubernetes namespace
"""
