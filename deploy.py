from requests import Session
import json
import os

portainer_api_token = os.getenv("PORTAINER_API_TOKEN")
portainer_url = f"{os.getenv("PORTAINER_URL")}/api"
stack = os.getenv("STACK")
stacks = json.loads(os.getenv("STACKS"))

r = requests.Session()
r.headers.update({"Content-Type": "application/json", "X-API-Key": portainer_api_token})

portainer_endpoints = []
response = r.get(f"{portainer_url}/endpoints")
if response.status_code == 200:
    portainer_endpoints = response.json()
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(portainer_endpoints)

portainer_stacks = []
response = r.get(f"{portainer_url}/stacks")
if response.status_code == 200:
    portainer_stacks = response.json()
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(portainer_stacks)
