import importlib
import pkgutil

import app.tools


def load_tools():

    discovered_tools = {}

    for module_info in pkgutil.walk_packages(
        app.tools.__path__,
        app.tools.__name__ + "."
    ):

        module_name = module_info.name

        try:

            module = importlib.import_module(
                module_name
            )

            for attribute_name in dir(module):

                attribute = getattr(
                    module,
                    attribute_name
                )

                if getattr(
                    attribute,
                    "is_agent_tool",
                    False
                ):

                    discovered_tools[
                        attribute.tool_name
                    ] = {
                        "function": attribute,

                        "description":
                            attribute.tool_description
                    }

        except Exception as exc:

            print(
                f"Failed to load tool module "
                f"{module_name}: {exc}"
            )

    return discovered_tools


def get_tools():

    return load_tools()
