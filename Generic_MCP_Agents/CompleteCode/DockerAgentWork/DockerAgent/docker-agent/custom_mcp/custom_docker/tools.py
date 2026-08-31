from typing import Any

from app.docker_tools import (
    docker_ps,
    docker_images,
    docker_container_inspect,
    docker_container_logs,
)


def list_containers() -> dict[str, Any]:
    """
    Reuse the existing Docker container implementation.
    """

    return docker_ps()


def list_images() -> dict[str, Any]:
    """
    Reuse the existing Docker image implementation.
    """

    return docker_images()


def inspect_container(
    name: str,
) -> dict[str, Any]:
    """
    Reuse the existing Docker inspect implementation.
    """

    return docker_container_inspect(name)


def container_logs(
    name: str,
    tail: int = 100,
) -> dict[str, Any]:
    """
    Reuse the existing Docker logs implementation.
    """

    return docker_container_logs(
        name=name,
        tail=tail,
    )
