import requests
import yaml

with open("configs/grafana-config.yaml") as f:
    cfg = yaml.safe_load(f)

url = cfg["grafana_url"]
user = cfg["username"]
password = cfg["password"]

response = requests.get(
    f"{url}/api/health",
    auth=(user, password)
)

print("Status:", response.status_code)
print(response.text)
