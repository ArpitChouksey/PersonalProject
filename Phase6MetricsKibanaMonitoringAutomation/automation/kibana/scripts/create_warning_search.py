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


def create_warning_search(dataview_id):

    payload = {
        "attributes": {
            "title":
            f"{RESOURCE_NAME}-warnings",

            "kibanaSavedObjectMeta": {
                "searchSourceJSON": json.dumps({
                    "index": dataview_id,
                    "query": {
                        "language": "kuery",
                        "query":
                        f'kubernetes.container_name:"{RESOURCE_NAME}" and log:*WARN*'
                    },
                    "filter": []
                })
            }
        }
    }

    response = requests.post(
        f"{KIBANA_URL}/api/saved_objects/search",
        headers={
            "kbn-xsrf": "true",
            "Content-Type": "application/json"
        },
        json=payload
    )

    data = response.json()

    print(
        f"Warning Search Created : {data['id']}"
    )

    return data["id"]
