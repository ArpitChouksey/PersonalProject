from app.docker_tools import get_docker_tools
from app.linux_tools import get_linux_tools


def get_all_tools():
    """
    Return all tools available to the agent.
    """

    tools = {}

    tools.update(get_docker_tools())
    tools.update(get_linux_tools())

    return tools
