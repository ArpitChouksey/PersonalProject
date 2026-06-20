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
    "ENVIRONMENT",
    "dev"
)


def find_objects(object_type):

    response = requests.get(
        f"{KIBANA_URL}/api/saved_objects/_find",
        headers={
            "kbn-xsrf": "true"
        },
        params={
            "type": object_type,
            "search": RESOURCE_NAME,
            "search_fields": "title",
            "per_page": 100
        }
    )

    data = response.json()

    return data.get(
        "saved_objects",
        []
    )


def delete_object(
    object_type,
    object_id
):

    response = requests.delete(
        f"{KIBANA_URL}/api/saved_objects/{object_type}/{object_id}",
        headers={
            "kbn-xsrf": "true"
        }
    )

    if response.status_code in [200, 204]:

        print(
            f"Deleted {object_type} : {object_id}"
        )

    else:

        print(
            f"Failed deleting {object_type} : {object_id}"
        )


def delete_workspace():

    print(
        f"Deleting resources for {RESOURCE_NAME}"
    )

    #
    # Dashboards
    #

    dashboards = find_objects(
        "dashboard"
    )

    for dashboard in dashboards:

        delete_object(
            "dashboard",
            dashboard["id"]
        )

    #
    # Saved Searches
    #

    searches = find_objects(
        "search"
    )

    for search in searches:

        delete_object(
            "search",
            search["id"]
        )

    #
    # Data Views
    #

    dataviews = find_objects(
        "index-pattern"
    )

    for dataview in dataviews:

        delete_object(
            "index-pattern",
            dataview["id"]
        )

    print(
        f"{RESOURCE_NAME} cleanup completed"
    )


if __name__ == "__main__":
    delete_workspace()
