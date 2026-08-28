import inspect
from functools import wraps


def kubernetes_tool(func):
    """
    Marks a Python function as an Agent tool.
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)

    wrapper.is_agent_tool = True
    wrapper.tool_name = func.__name__
    wrapper.tool_description = inspect.getdoc(func) or ""

    return wrapper
