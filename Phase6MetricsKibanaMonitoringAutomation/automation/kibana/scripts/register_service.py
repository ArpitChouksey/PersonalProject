import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

RESOURCE_FILE = os.path.join(
    BASE_DIR,
    "config",
    "resources.json"
)

RESOURCE_NAME = os.getenv("RESOURCE_NAME")
RESOURCE_TYPE = os.getenv("RESOURCE_TYPE")
ENVIRONMENT = os.getenv("ENVIRONMENT")
NAMESPACE = os.getenv("NAMESPACE")


def register_resource():

    with open(RESOURCE_FILE, "r") as f:
        resources = json.load(f)

    resources[RESOURCE_NAME] = {
        "type": RESOURCE_TYPE,
        "namespace": NAMESPACE,
        "environment": ENVIRONMENT
    }

    with open(RESOURCE_FILE, "w") as f:
        json.dump(
            resources,
            f,
            indent=4
        )

    print(
        f"{RESOURCE_NAME} registered"
    )


if __name__ == "__main__":
    register_resource()
