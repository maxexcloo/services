from requests import Session
import json
import os

app = os.getenv("APP")
apps = json.loads(os.getenv("APPS"))
portainer_api_token = os.getenv("PORTAINER_API_TOKEN")
portainer_url = f"{os.getenv("PORTAINER_URL")}/api"

r = requests.Session()
r.headers.update({"Content-Type": "application/json", "X-API-Key": portainer_api_token})

endpoints = []
response = r.get(f"{portainer_url}/endpoints")
if response.status_code == 200:
    endpoints = response.json()
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(endpoints)

stacks = []
response = r.get(f"{portainer_url}/stacks")
if response.status_code == 200:
    stacks = response.json()
else:
    print("Failed to retrieve endpoints:", response.status_code)

print(stacks)
