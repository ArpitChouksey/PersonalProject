from app.agent.tool import kubernetes_tool


@kubernetes_tool
def stream_pod_logs(
    pod_name: str,
    namespace: str = "default"
):
    """
    Stream live logs from a Kubernetes pod.
    Use this only when live log streaming is specifically requested.
    """

    return {
        "status": "info",
        "resource": "pod-logs",
        "message": (
            "Live streaming is not performed inside "
            "the HTTP request. Use kubectl logs -f "
            f"{pod_name} -n {namespace} from a terminal."
        )
    }
