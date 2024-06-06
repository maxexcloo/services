import json
import os
import requests

dir = os.getenv("APP_DIR")
portainer_headers = {"Content-Type": "application/json", "X-API-Key": os.getenv("PORTAINER_API_TOKEN")}
portainer_url = f"{os.getenv("PORTAINER_URL")}/api"
stacks = json.loads(os.getenv("STACKS"))

endpoints = []
response = requests.get(f"{portainer_url}/endpoints", headers=portainer_headers)
if response.status_code == 200:
    data = response.json()
    for endpoint in response.json():
        endpoints.append({"id": endpoint["Id"], "name": endpoint["Name"]})
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(endpoints)
