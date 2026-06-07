from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

SN_INSTANCE = os.getenv("SN_INSTANCE")
SN_USER = os.getenv("SN_USER")
SN_PASS = os.getenv("SN_PASS")

@app.route("/health")
def health():
    return "OK", 200

@app.route("/alert", methods=["POST"])
def alert():

    payload = request.json

    alerts = payload.get("alerts", [])

    for alert in alerts:

        alert_name = alert.get("labels", {}).get(
            "alertname",
            "Unknown Alert"
        )

        description = str(alert)

        body = {
            "short_description": f"Prometheus Alert - {alert_name}",
            "description": description,
            "impact": "2",
            "urgency": "2"
        }

        url = (
            f"https://{SN_INSTANCE}.service-now.com"
            "/api/now/table/incident"
        )

        response = requests.post(
            url,
            auth=(SN_USER, SN_PASS),
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            json=body,
            timeout=30
        )

        print(response.status_code)
        print(response.text)

    return jsonify({"status": "success"})


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )
