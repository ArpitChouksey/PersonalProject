import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

REGISTRY_FILE = os.path.join(
    BASE_DIR,
    "records",
    "kibana_registry.json"
)


def load_registry():

    if not os.path.exists(REGISTRY_FILE):
        return []

    with open(REGISTRY_FILE, "r") as f:
        return json.load(f)


def save_registry(data):

    with open(REGISTRY_FILE, "w") as f:
        json.dump(
            data,
            f,
            indent=4
        )


def resource_exists(resource_name):

    registry = load_registry()

    for item in registry:

        if item["resource_name"] == resource_name:
            return True

    return False


def add_resource(entry):

    registry = load_registry()

    registry.append(entry)

    save_registry(registry)
