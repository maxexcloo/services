import json
import os
import requests

app = os.getenv("DIR")
apps = json.loads(os.getenv("APPS"))
portainer_headers = {"Content-Type": "application/json", "X-API-Key": os.getenv("PORTAINER_API_TOKEN")}
portainer_url = f"{os.getenv("PORTAINER_URL")}/api"

endpoints = []
stacks = []

response = requests.get(f"{portainer_url}/endpoints", headers=portainer_headers)
if response.status_code == 200:
    for endpoint in response.json():
        endpoints.append({"id": endpoint["Id"], "name": endpoint["Name"]})
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(endpoints)

response = requests.get(f"{portainer_url}/stacks", headers=portainer_headers)
if response.status_code == 200:
    stacks = response.json()
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(stacks)
