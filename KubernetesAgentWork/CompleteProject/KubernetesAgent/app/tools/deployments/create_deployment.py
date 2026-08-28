from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def create_deployment(
    name: str,
    image: str,
    namespace: str = "default",
    replicas: int = 1
):
    """
    Create a Kubernetes deployment.
    """

    result = run_kubectl(
        [
            "create",
            "deployment",
            name,
            f"--image={image}",
            f"--replicas={replicas}",
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
        "image": image,
        "replicas": replicas,
        "title": "Kubernetes Deployment",
        "table": [
            "Name",
            "Namespace",
            "Image",
            "Replicas"
        ],
        "rows": [
            [
                name,
                namespace,
                image,
                replicas
            ]
        ],
        "summary": (
            f"Deployment '{name}' created successfully "
            f"with {replicas} replica(s)."
        )
    }


create_deployment.tool_name = "create_deployment"

create_deployment.tool_description = """
Create a Kubernetes deployment.

Arguments:

- name: Deployment name
- image: Container image
- namespace: Kubernetes namespace
- replicas: Number of replicas
"""
