from mcp.server.fastmcp import FastMCP
from kubernetes import client, config
from kubernetes.client.exceptions import ApiException


# ============================================================
# CONFIGURATION
# ============================================================

MCP_HOST = "127.0.0.1"
MCP_PORT = 8081


# ============================================================
# MCP SERVER
# ============================================================

mcp = FastMCP(
    "Custom Kubernetes MCP",
    host=MCP_HOST,
    port=MCP_PORT,
    streamable_http_path="/mcp",
)


# ============================================================
# KUBERNETES CLIENT
# ============================================================

try:
    config.load_kube_config()

    print(
        "[Kubernetes] kubeconfig loaded successfully"
    )

except Exception as e:
    print(
        f"[Kubernetes] Failed to load kubeconfig: {e}"
    )
    raise


core_v1 = client.CoreV1Api()


# ============================================================
# CUSTOM TOOL
# ============================================================

@mcp.tool()
def restart_pod(
    pod_name: str,
    namespace: str = "default",
) -> str:
    """
    Restart a Kubernetes Pod.

    The pod is deleted using the Kubernetes API.
    If the pod is managed by a Deployment, ReplicaSet,
    StatefulSet, or another Kubernetes controller,
    Kubernetes should create a replacement pod.

    Args:
        pod_name: Name of the Kubernetes pod.
        namespace: Kubernetes namespace containing the pod.
    """

    print()
    print("=" * 60)
    print("[Custom MCP] restart_pod")
    print("=" * 60)

    print(
        f"[Custom MCP] Pod       : {pod_name}"
    )

    print(
        f"[Custom MCP] Namespace : {namespace}"
    )

    try:

        # ====================================================
        # 1. CHECK POD EXISTS
        # ====================================================

        pod = core_v1.read_namespaced_pod(
            name=pod_name,
            namespace=namespace,
        )

        print(
            "[Custom MCP] Pod found"
        )

        # ====================================================
        # 2. CHECK POD OWNER
        # ====================================================

        owners = (
            pod.metadata.owner_references or []
        )

        if not owners:

            print(
                "[Custom MCP] No owner controller found"
            )

            return (
                f"Pod '{pod_name}' in namespace "
                f"'{namespace}' is a standalone pod "
                f"and has no controller. "
                f"Restart was NOT performed."
            )

        owner = owners[0]

        print(
            f"[Custom MCP] Owner: "
            f"{owner.kind}/{owner.name}"
        )

        # ====================================================
        # 3. DELETE POD
        # ====================================================

        print(
            "[Custom MCP] Deleting pod..."
        )

        core_v1.delete_namespaced_pod(
            name=pod_name,
            namespace=namespace,
            body=client.V1DeleteOptions(),
        )

        print(
            "[Custom MCP] Pod deleted"
        )

        # ====================================================
        # 4. RETURN RESULT
        # ====================================================

        return (
            f"Pod '{pod_name}' in namespace "
            f"'{namespace}' was restarted successfully. "
            f"The existing pod was deleted. "
            f"Owner: {owner.kind}/{owner.name}. "
            f"Kubernetes should create a replacement pod."
        )

    except ApiException as e:

        # ====================================================
        # POD NOT FOUND
        # ====================================================

        if e.status == 404:

            return (
                f"Pod '{pod_name}' was not found "
                f"in namespace '{namespace}'."
            )

        # ====================================================
        # OTHER KUBERNETES ERROR
        # ====================================================

        return (
            f"Failed to restart pod "
            f"'{pod_name}' in namespace "
            f"'{namespace}'. "
            f"Kubernetes API error: {e.reason}"
        )

    except Exception as e:

        return (
            f"Failed to restart pod "
            f"'{pod_name}' in namespace "
            f"'{namespace}': {str(e)}"
        )


# ============================================================
# START SERVER
# ============================================================

if __name__ == "__main__":

    print()
    print("=" * 60)
    print("Custom Kubernetes MCP Server")
    print("=" * 60)

    print()
    print("Available tools:")
    print("  - restart_pod")

    print()
    print("Kubernetes context:")
    print("  docker-desktop")

    print()
    print(
        "Starting Streamable HTTP MCP server..."
    )

    print(
        f"Server: http://{MCP_HOST}:{MCP_PORT}/mcp"
    )

    print()
    print("=" * 60)
    print()

    # ========================================================
    # IMPORTANT:
    # host and port are configured in FastMCP(...)
    # NOT in mcp.run(...)
    # ========================================================

    mcp.run(
        transport="streamable-http"
    )
