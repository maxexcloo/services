import json
import os
import requests
import sys


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
            if file_path.lower().endswith(".json"):
                return json.load(file)
            else:
                return file.read()
    except FileNotFoundError:
        raise SystemExit(f"Error: The file {file_path} was not found.")
    except json.JSONDecodeError:
        raise SystemExit(f"Error: The file {file_path} contains invalid JSON.")
    except Exception as e:
        raise SystemExit(f"An unexpected error occurred: {error}")


def read_json(value):
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        raise SystemExit(f"Error: The value {value} contains invalid JSON.")
    except Exception as error:
        raise SystemExit(f"An unexpected error occurred: {error}")


if __name__ == "__main__":
    item = sys.argv[1]
    item_docker_file = read_file(f"{item}/docker-compose.yaml")
    item_endpoint_names = read_file(f"{item}/endpoints.json")
    portainer = APIClient(
        f"{read_env_var('PORTAINER_URL')}/api",
        {
            "Content-Type": "application/json",
            "X-API-Key": read_env_var("PORTAINER_API_TOKEN"),
        },
    )

    defaults = read_json(read_env_var("DEFAULTS"))
    secrets = read_json(read_env_var("SECRETS"))
    servers = read_json(read_env_var("SERVERS"))
    websites = read_json(read_env_var("WEBSITES"))

    portainer_endpoints = []
    response = portainer.get(f"endpoints")
    if response.status_code == 200:
        portainer_endpoints = response.json()
    else:
        raise SystemExit(f"Failed to retrieve Portainer endpoints: {response.status_code}")

    portainer_stacks = []
    response = portainer.get(f"stacks")
    if response.status_code == 200:
        portainer_stacks = response.json()
    else:
        raise SystemExit(f"Failed to retrieve Portainer stacks: {response.status_code}")

    item_endpoints = [
        {"id": portainer_endpoint["Id"], "name": portainer_endpoint["Name"]}
        for portainer_endpoint in portainer_endpoints
        if "all" in item_endpoint_names or portainer_endpoint["Name"] in item_endpoint_names
    ]

    print(f"Processing {item}:")
    for item_endpoint in item_endpoints:
        item_env = []
        for key, value in defaults.items():
            item_env.append({"name": f"DEFAULT_{key.upper()}", "value": str(value)})
        for secret in secrets:
            if secret["app_type"] == item and "host" not in secret or secret["app_type"] == item and secret["host"] == item_endpoint["name"]:
                for key, value in secret.items():
                    item_env.append({"name": f"SECRET_{key.upper()}", "value": str(value)})
        for server in servers.values():
            if server["host"] == item_endpoint["name"]:
                for key, value in server.items():
                    item_env.append({"name": f"SERVER_{key.upper()}", "value": str(value)})
        for website in websites.values():
            if website["app_type"] == item and website["host"] == item_endpoint["name"]:
                for key, value in website.items():
                    item_env.append({"name": f"WEBSITE_{key.upper()}", "value": str(value)})

        if any(portainer_stack["EndpointId"] == item_endpoint["id"] and portainer_stack["Name"] == item for portainer_stack in portainer_stacks):
            print(f"Exists on endpoint '{item_endpoint['name']}', redeploying...")
            data = {
                "env": item_env,
                "prune": True,
                "pullImage": True,
                "stackFileContent": item_docker_file,
            }
            id = next(portainer_stack["Id"] for portainer_stack in portainer_stacks if portainer_stack["EndpointId"] == item_endpoint["id"] and portainer_stack["Name"] == item)
            params = {
                "endpointId": item_endpoint["id"],
            }
            response = portainer.put(f"stacks/{id}", json=data, params=params)
            if response.status_code == 200:
                print(f"Successfully redeployed existing Portainer stack '{item}' to endpoint '{item_endpoint['name']}'.")
            else:
                sys.exit(f"Failed to redeploy existing Portainer stack '{item}' to endpoint '{item_endpoint['name']}': {response.status_code}")
        else:
            print(f"Does not exist on endpoint '{item_endpoint['name']}', deploying...")
            data = {
                "env": item_env,
                "fromAppTemplate": False,
                "name": item,
                "stackFileContent": item_docker_file,
            }
            params = {
                "endpointId": item_endpoint["id"],
            }
            response = portainer.post(f"stacks/create/standalone/string", json=data, params=params)
            if response.status_code == 200:
                print(f"Successfully deployed new Portainer stack '{item}' to endpoint '{item_endpoint['name']}'.")
            else:
                sys.exit(f"Failed to deploy new Portainer stack '{item}' to endpoint '{item_endpoint['name']}': {response.status_code}")
