import json
import os
import requests

class APIClient:
    def __init__(self, base_url, headers):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update(headers)

    def delete(self, endpoint, **kwargs):
        return self.session.delete(f"{self.base_url}/{endpoint}", **kwargs)

    def get(self, endpoint, **kwargs):
        return self.session.get(f"{self.base_url}/{endpoint}", **kwargs)

    def post(self, endpoint, **kwargs):
        return self.session.post(f"{self.base_url}/{endpoint}", **kwargs)

    def put(self, endpoint, **kwargs):
        return self.session.put(f"{self.base_url}/{endpoint}", **kwargs)

def read_env_var(var_name):
    try:
        value = os.getenv(var_name)
        if value is None:
            raise ValueError(f"Environment variable '{var_name}' is not set.")
        return value
    except Exception as error:
        raise SystemExit(f"An error occurred while reading the environment variable '{var_name}': {error}")

def read_file(file_path):
    try:
        with open(file_path, "r") as file:
            return file.read()
    except FileNotFoundError:
        raise SystemExit(f"Error: The file {file_path} was not found.")
    except Exception as error:
        raise SystemExit(f"An unexpected error occurred: {error}")

def read_json(value):
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        raise SystemExit(f"Error: The value {value} contains invalid JSON.")
    except Exception as error:
        raise SystemExit(f"An unexpected error occurred: {error}")

if __name__ == "__main__":
    item = read_env_var("DIR")
    item_endpoint_names = read_json(read_file(f"{item}/endpoints.json"))
    portainer = APIClient(f"{read_env_var("PORTAINER_URL")}/api", {"Content-Type": "application/json", "X-API-Key": read_env_var("PORTAINER_API_TOKEN")})
    websites = read_json(read_env_var("WEBSITES"))

    portainer_endpoints = []
    response = portainer.get(f"{portainer_url}/endpoints")
    if response.status_code == 200:
        portainer_endpoints = response.json()
    else:
        raise SystemExit(f"Failed to retrieve Portainer endpoints: {response.status_code}")

    portainer_stacks = []
    response = portainer.get(f"{portainer_url}/stacks")
    if response.status_code == 200:
        portainer_stacks = response.json()
    else:
        raise SystemExit(f"Failed to retrieve Portainer stacks: {response.status_code}")

    item_endpoints = [
        {"id": portainer_endpoint["Id"], "name": portainer_endpoint["Name"]} for portainer_endpoint in portainer_endpoints
        if "all" in item_endpoint_names or portainer_endpoint["Name"] in item_endpoint_names
    ]

    item_env = []
    for line in read_file(f"{stack}/.env"):
        split = line.rstrip().split("=")
        item_env.append({split[0]: split[1]})

    for item_endpoint in item_endpoints:
        if any(portainer_stack["EndpointId"] == item_endpoint.id and portainer_stack["Name"] == item for portainer_stack in portainer_stacks):
            print(f"'{item}' exists on endpoint '{item_endpoint.name}', redeploying...")
            data = {
                "env": item_env,
                "prune": True,
                "pullImage": True,
                "stackFileContent": read_file(f"{item}/docker-compose.yaml")
            }
            params = {
                "endpointId": item_endpoint.id,
                "id": next(portainer_stack["Id"] for portainer_stack in portainer_stacks if portainer_stack["EndpointId"] == item_endpoint.id and portainer_stack["Name"] == item)
            }
            response = portainer.put(f"{portainer_url}/stacks", data=data, params=params)
            if response.status_code == 200:
                print(f"Successfully redeployed existing Portainer stack '{item}' to endpoint '{item_endpoint.name}'.")
            else:
                print(f"Failed to redeploy existing Portainer stack '{item}' to endpoint '{item_endpoint.name}':", response.status_code)
        else:
            print(f"'{item}' does not exist on endpoint '{item_endpoint.name}', deploying...")
            data = {
                "env": stack_env,
                "fromAppTemplate": False,
                "name": stack,
                "stackFileContent": read_file(f"{stack}/docker-compose.yaml")
            }
            response = portainer.post(f"{portainer_url}/stacks/create/standalone/string", data=data)
            if response.status_code == 200:
                print(f"Successfully deployed new Portainer stack '{item}' to endpoint '{item_endpoint.name}'.")
            else:
                print(f"Failed to deploy new Portainer stack '{item}' to endpoint '{item_endpoint.name}':", response.status_code)
