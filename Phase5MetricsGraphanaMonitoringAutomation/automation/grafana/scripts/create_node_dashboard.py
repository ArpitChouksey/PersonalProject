import json
import yaml
import requests
from datetime import datetime

DASHBOARD_TITLE = "SRE-AUTO-Node-Dashboard"

# Load Grafana Config
with open("configs/grafana-config.yaml") as f:
    cfg = yaml.safe_load(f)

# Load Dashboard Template
with open("templates/node_dashboard.json") as f:
    dashboard_payload = json.load(f)

# Create Dashboard
response = requests.post(
    f"{cfg['grafana_url']}/api/dashboards/db",
    auth=(cfg["username"], cfg["password"]),
    headers={"Content-Type": "application/json"},
    json=dashboard_payload,
    timeout=30
)

print("Status:", response.status_code)
print(response.text)

if response.status_code != 200:
    exit(1)

result = response.json()

# Registry Entry
entry = {
    "uid": result["uid"],
    "title": DASHBOARD_TITLE,
    "type": "node",
    "created_by": "arpit",
    "created_at": datetime.utcnow().isoformat(),
    "deleted_by": None,
    "deleted_at": None,
    "status": "ACTIVE"
}

# Read Registry
with open("records/dashboard_registry.json") as f:
    registry = json.load(f)

registry.append(entry)

# Write Registry
with open("records/dashboard_registry.json", "w") as f:
    json.dump(registry, f, indent=4)

# Audit Log
with open("logs/dashboard_audit.log", "a") as f:
    f.write(
        f"{datetime.utcnow()} | CREATE | {DASHBOARD_TITLE} | UID={result['uid']}\n"
    )

print("Dashboard Registry Updated")
print("Audit Log Updated")
