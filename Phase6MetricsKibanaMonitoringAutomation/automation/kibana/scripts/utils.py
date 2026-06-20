import json
from datetime import datetime, UTC


def load_registry(registry_file):
    try:
        with open(registry_file, "r") as f:
            return json.load(f)
    except Exception:
        return []


def save_registry(registry_file, data):
    with open(registry_file, "w") as f:
        json.dump(data, f, indent=4)


def write_audit_log(audit_file, action, target, status):
    with open(audit_file, "a") as f:
        f.write(
            f"{datetime.now(UTC)} | {action} | {target} | {status}\n"
        )
