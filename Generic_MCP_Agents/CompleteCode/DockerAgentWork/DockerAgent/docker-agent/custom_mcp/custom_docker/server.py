from mcp.server.mcpserver import MCPServer

from custom_mcp.custom_docker.tools import (
    list_containers,
    list_images,
    inspect_container,
    container_logs,
)


# ============================================================
# CUSTOM DOCKER MCP SERVER
# ============================================================

mcp = MCPServer(
    "Custom Docker MCP",
    instructions=(
        "Custom MCP server for the Docker Agent project. "
        "Provides Docker container and image operations using "
        "the existing Docker implementation."
    ),
)


# ============================================================
# CONTAINER TOOLS
# ============================================================

@mcp.tool()
def docker_list_containers() -> dict:
    """
    List all Docker containers.

    Use this tool when the user wants to know:
    - running containers
    - stopped containers
    - container status
    - container names
    """

    return list_containers()


@mcp.tool()
def docker_inspect_container(
    name: str,
) -> dict:
    """
    Inspect a Docker container by name or container ID.

    Args:
        name: Docker container name or container ID.
    """

    return inspect_container(name)


@mcp.tool()
def docker_container_logs(
    name: str,
    tail: int = 100,
) -> dict:
    """
    Get recent logs from a Docker container.

    Args:
        name: Docker container name or container ID.
        tail: Number of log lines to retrieve.
    """

    return container_logs(
        name=name,
        tail=tail,
    )


# ============================================================
# IMAGE TOOLS
# ============================================================

@mcp.tool()
def docker_list_images() -> dict:
    """
    List Docker images available locally.
    """

    return list_images()


# ============================================================
# SERVER ENTRYPOINT
# ============================================================

if __name__ == "__main__":
    mcp.run(
        transport="streamable-http",
    )
