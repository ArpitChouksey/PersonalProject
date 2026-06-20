import os

from registry import (
    resource_exists,
    add_resource,
    load_registry
)

from register_resource import register_resource
from validate_logs import validate_logs

from create_dataview import create_dataview
from create_saved_search import create_saved_search
from create_error_search import create_error_search
from create_warning_search import create_warning_search
from create_dashboard import create_dashboard

RESOURCE_NAME = os.getenv("RESOURCE_NAME")
RESOURCE_TYPE = os.getenv("RESOURCE_TYPE")
ENVIRONMENT = os.getenv("ENVIRONMENT")


def create_workspace():

    print(
        f"RESOURCE_NAME = {RESOURCE_NAME}"
    )

    print(
        f"REGISTRY = {load_registry()}"
    )

    if resource_exists(RESOURCE_NAME):

        print(
            f"{RESOURCE_NAME} already exists"
        )

        return

    print(
        "Registry validation passed"
    )

    register_resource()

    if not validate_logs():

        print("No logs found")
        return

    dataview_id = create_dataview()

    all_logs_id = create_saved_search(
        dataview_id
    )

    error_id = create_error_search(
        dataview_id
    )

    warning_id = create_warning_search(
        dataview_id
    )

    dashboard_id = create_dashboard()

    add_resource({
        "resource_name": RESOURCE_NAME,
        "resource_type": RESOURCE_TYPE,
        "environment": ENVIRONMENT,
        "dataview_id": dataview_id,
        "all_logs_search_id": all_logs_id,
        "error_search_id": error_id,
        "warning_search_id": warning_id,
        "dashboard_id": dashboard_id,
        "status": "active"
    })

    print(
        "Workspace Created Successfully"
    )


if __name__ == "__main__":
    create_workspace()
