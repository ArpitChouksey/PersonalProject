import json
import requests
import sys
import os
from datetime import datetime, UTC

if len(sys.argv) != 4:
    print("Usage: python3 delete_dashboard.py <type> <team> <env>")
    sys.exit(1)

dashboard_type = sys.argv[1].lower()
team = sys.argv[2].upper()
environment = sys.argv[3].upper()

dashboard_title = f"SRE-AUTO-{team}-{environment}-{dashboard_type.upper()}"

cfg = {
    "grafana_url": os.getenv("GRAFANA_URL"),
    "username": os.getenv("GRAFANA_USER"),
    "password": os.getenv("GRAFANA_PASSWORD")
}

with open("records/dashboard_registry.json") as f:
    registry = json.load(f)

dashboard = None

for item in registry:
    if (
        item["title"] == dashboard_title
        and item["status"] == "ACTIVE"
    ):
        dashboard = item
        break

if dashboard is None:
    print(f"Dashboard not found: {dashboard_title}")
    sys.exit(1)

uid = dashboard["uid"]

response = requests.delete(
    f"{cfg['grafana_url']}/api/dashboards/uid/{uid}",
    auth=(cfg["username"], cfg["password"]),
    timeout=30
)

print(response.status_code)
print(response.text)

if response.status_code != 200:
    sys.exit(1)

dashboard["status"] = "DELETED"
dashboard["deleted_by"] = "arpit"
dashboard["deleted_at"] = datetime.now(UTC).isoformat()

with open("records/dashboard_registry.json", "w") as f:
    json.dump(registry, f, indent=4)

with open("logs/dashboard_audit.log", "a") as f:
    f.write(
        f"{datetime.now(UTC)} | DELETE | "
        f"{dashboard_title} | UID={uid}\n"
    )

print(f"Dashboard Deleted: {dashboard_title}")
