from kubernetes import client, config


def get_pod_logs(
    name: str,
    namespace: str = "default",
    container: str = None,
    tail_lines: int = 100
):
    """
    Get logs from a Kubernetes Pod.
    """

    try:
        config.load_kube_config()

        v1 = client.CoreV1Api()

        kwargs = {
            "name": name,
            "namespace": namespace,
            "tail_lines": tail_lines,
        }

        if container:
            kwargs["container"] = container

        logs = v1.read_namespaced_pod_log(**kwargs)

        return {
            "status": "success",
            "resource": "pod_logs",
            "name": name,
            "namespace": namespace,
            "logs": logs,
        }

    except Exception as e:
        return {
            "status": "error",
            "resource": "pod_logs",
            "name": name,
            "namespace": namespace,
            "message": str(e),
        }


# ============================================================
# AGENT TOOL METADATA
# ============================================================

get_pod_logs.is_agent_tool = True
get_pod_logs.tool_name = "get_pod_logs"

get_pod_logs.tool_description = """
Get logs from a Kubernetes Pod.

Use this tool when the user wants to:

- show pod logs
- get pod logs
- check pod logs
- view pod logs
- show logs for a pod
- check logs of a pod

Arguments:

- name:
    Name of the Kubernetes pod.

- namespace:
    Kubernetes namespace.
    Default: default

- container:
    Optional container name.

- tail_lines:
    Number of log lines to return.
    Default: 100
"""
