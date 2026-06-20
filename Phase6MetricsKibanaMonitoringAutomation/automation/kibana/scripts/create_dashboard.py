import json
import os
import requests

BASE_DIR = os.path.dirname(
    os.path.dirname(__file__)
)

CONFIG_FILE = os.path.join(
    BASE_DIR,
    "config",
    "kibana_config.json"
)

with open(CONFIG_FILE) as f:
    config = json.load(f)

KIBANA_URL = config["kibana_url"]

RESOURCE_NAME = os.getenv(
    "RESOURCE_NAME"
)

ENVIRONMENT = os.getenv(
    "ENVIRONMENT"
)


def create_dashboard():

    payload = {
        "attributes": {
            "title":
            f"{RESOURCE_NAME}-{ENVIRONMENT}-dashboard"
        }
    }

    response = requests.post(
        f"{KIBANA_URL}/api/saved_objects/dashboard",
        headers={
            "kbn-xsrf": "true",
            "Content-Type":
            "application/json"
        },
        json=payload
    )

    data = response.json()

    print(
        f"Dashboard Created : {data['id']}"
    )

    return data["id"]


if __name__ == "__main__":
    create_dashboard()
