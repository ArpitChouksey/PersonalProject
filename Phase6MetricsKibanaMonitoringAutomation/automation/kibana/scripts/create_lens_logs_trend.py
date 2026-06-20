import json
import os
import requests

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

CONFIG_FILE = os.path.join(
    BASE_DIR,
    "config",
    "kibana_config.json"
)

with open(CONFIG_FILE) as f:
    config = json.load(f)

KIBANA_URL = config["kibana_url"]

RESOURCE_NAME = os.getenv("RESOURCE_NAME")


def create_lens_logs_trend(dataview_id):

    payload = {
        "attributes": {
            "title":
            f"{RESOURCE_NAME}-log-trend",

            "description":
            "Auto Generated Log Trend",

            "visualizationType":
            "lnsXY"
        }
    }

    response = requests.post(
        f"{KIBANA_URL}/api/saved_objects/lens",
        headers={
            "kbn-xsrf": "true",
            "Content-Type": "application/json"
        },
        json=payload
    )

    if response.status_code not in [200, 201]:
        print(response.text)
        return None

    data = response.json()

    print(
        f"Lens Visualization Created : {data['id']}"
    )

    return data["id"]
