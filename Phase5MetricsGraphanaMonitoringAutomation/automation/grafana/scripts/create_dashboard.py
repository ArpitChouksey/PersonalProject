import json
import yaml
import requests
import sys
import os
from datetime import datetime, UTC

# --------------------------------------------------
# Arguments
# --------------------------------------------------

if len(sys.argv) not in [4, 5]:
    print("Usage:")
    print("python3 create_dashboard.py <type> <team> <env> [instance_id]")
    sys.exit(1)

dashboard_type = sys.argv[1].lower()
team = sys.argv[2].upper()
environment = sys.argv[3].upper()

instance_id = None

if dashboard_type == "aws-ec2":

    if len(sys.argv) != 5:
        print("AWS EC2 dashboard requires instance_id")
        print(
            "python3 create_dashboard.py aws-ec2 sre dev i-08f60123e47c04933"
        )
        sys.exit(1)

    instance_id = sys.argv[4]

# --------------------------------------------------
# Dashboard Templates
# --------------------------------------------------

template_map = {
    "node": {
        "file": "templates/node_dashboard.json"
    },
    "spring": {
        "file": "templates/spring_dashboard.json"
    },
    "postgres": {
        "file": "templates/postgres_dashboard.json"
    },
    "python": {
        "file": "templates/python_dashboard.json"
    },
    "aws-ec2": {
        "file": "templates/aws_ec2_dashboard.json"
    }
}

if dashboard_type not in template_map:
    print("Unsupported dashboard type")
    sys.exit(1)

dashboard_title = (
    f"SRE-AUTO-{team}-{environment}-{dashboard_type.upper()}"
)

# --------------------------------------------------
# Load Config
# --------------------------------------------------

#with open("configs/grafana-config.yaml") as f:
#    cfg = yaml.safe_load(f)

cfg = {
    "grafana_url": os.getenv("GRAFANA_URL"),
    "username": os.getenv("GRAFANA_USER"),
    "password": os.getenv("GRAFANA_PASSWORD")
}

# --------------------------------------------------
# Load Registry
# --------------------------------------------------

with open("records/dashboard_registry.json") as f:
    registry = json.load(f)

# --------------------------------------------------
# Check Existing Dashboard
# --------------------------------------------------

existing_dashboard = None

for item in registry:

    if (
        item["title"] == dashboard_title
        and item["status"] == "ACTIVE"
    ):
        existing_dashboard = item
        break

# --------------------------------------------------
# Load Template
# --------------------------------------------------

with open(template_map[dashboard_type]["file"]) as f:
    dashboard_payload = json.load(f)

dashboard_payload["dashboard"]["title"] = dashboard_title

# --------------------------------------------------
# AWS EC2 Instance Injection
# --------------------------------------------------

if dashboard_type == "aws-ec2":

    for panel in dashboard_payload["dashboard"]["panels"]:

        if "targets" not in panel:
            continue

        for target in panel["targets"]:

            target["dimensions"] = {
                "InstanceId": instance_id
            }

            target["matchExact"] = True

# --------------------------------------------------
# Update Existing Dashboard
# --------------------------------------------------

if existing_dashboard:

    print(f"Dashboard already exists: {dashboard_title}")
    print(f"Updating UID: {existing_dashboard['uid']}")

    dashboard_payload["dashboard"]["uid"] = (
        existing_dashboard["uid"]
    )

    response = requests.post(
        f"{cfg['grafana_url']}/api/dashboards/db",
        auth=(cfg["username"], cfg["password"]),
        headers={
            "Content-Type": "application/json"
        },
        json=dashboard_payload,
        timeout=30
    )

    print(response.status_code)
    print(response.text)

    with open("logs/dashboard_audit.log", "a") as f:
        f.write(
            f"{datetime.now(UTC)} | UPDATE | "
            f"{dashboard_title} | "
            f"UID={existing_dashboard['uid']}\n"
        )

    sys.exit(0)

# --------------------------------------------------
# Create Dashboard
# --------------------------------------------------

response = requests.post(
    f"{cfg['grafana_url']}/api/dashboards/db",
    auth=(cfg["username"], cfg["password"]),
    headers={
        "Content-Type": "application/json"
    },
    json=dashboard_payload,
    timeout=30
)

print(response.status_code)
print(response.text)

if response.status_code != 200:
    sys.exit(1)

result = response.json()

# --------------------------------------------------
# Registry Record
# --------------------------------------------------

record = {
    "uid": result["uid"],
    "title": dashboard_title,
    "team": team,
    "environment": environment,
    "instance_id": instance_id,
    "type": dashboard_type,
    "created_by": "arpit",
    "created_at": datetime.now(UTC).isoformat(),
    "deleted_by": None,
    "deleted_at": None,
    "status": "ACTIVE"
}

registry.append(record)

with open("records/dashboard_registry.json", "w") as f:
    json.dump(registry, f, indent=4)

# --------------------------------------------------
# Audit Log
# --------------------------------------------------

with open("logs/dashboard_audit.log", "a") as f:
    f.write(
        f"{datetime.now(UTC)} | CREATE | "
        f"{dashboard_title} | "
        f"UID={result['uid']}\n"
    )

print("Dashboard Created")
