import os
import requests

RESOURCE_NAME = os.getenv(
    "RESOURCE_NAME"
)

ELASTIC_URL = "http://localhost:9200"


def validate_logs():

    response = requests.get(
        f"{ELASTIC_URL}/{RESOURCE_NAME}-logs-*/_count"
    )

    result = response.json()

    count = result.get(
        "count",
        0
    )

    if count > 0:

        print(
            f"Logs Found : {count}"
        )

        return True

    print(
        "Logs Not Found"
    )

    return False


if __name__ == "__main__":
    validate_logs()
