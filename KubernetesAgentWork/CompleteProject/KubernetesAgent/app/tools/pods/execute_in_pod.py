from app.agent.tool import kubernetes_tool
from app.tools.kubectl_helper import run_kubectl


@kubernetes_tool
def execute_in_pod(
    pod_name: str,
    command: str,
    namespace: str = "default"
):
    """
    Execute a command inside a running Kubernetes pod.
    """

    command_parts = command.split()

    result = run_kubectl(
        [
            "exec",
            pod_name,
            "-n",
            namespace,
            "--"
        ] + command_parts
    )

    if not result["success"]:
        return {
            "status": "error",
            "message": result["stderr"]
        }

    return {
        "status": "success",
        "resource": "pod-exec",
        "pod": pod_name,
        "output": result["stdout"]
    }
