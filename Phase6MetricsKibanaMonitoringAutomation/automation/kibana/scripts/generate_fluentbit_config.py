import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

SERVICES_FILE = os.path.join(
    BASE_DIR,
    "config",
    "services.json"
)

OUTPUT_FILE = os.path.join(
    BASE_DIR,
    "config",
    "generated_fluentbit.conf"
)


def generate():

    with open(SERVICES_FILE, "r") as f:
        services = json.load(f)

    config = ""

    for service, details in services.items():

        prefix = service.replace(
            "-service",
            ""
        )

        config += f"""
[FILTER]
    Name modify
    Match {prefix}.*
    Add service {service}
    Add environment {details['environment']}

[OUTPUT]
    Name es
    Match {prefix}.*
    Host elasticsearch
    Port 9200
    Logstash_Format On
    Logstash_Prefix {details['index']}
"""

    with open(
        OUTPUT_FILE,
        "w"
    ) as f:
        f.write(config)

    print(
        "Fluent Bit config generated"
    )


if __name__ == "__main__":
    generate()
