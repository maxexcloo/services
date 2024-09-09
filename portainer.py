import json
import os
import requests
import sys


class APIClient:
    def __init__(self, base_url, headers=None):
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        if headers:
            self.session.headers.update(headers)

    def _make_request(self, method, endpoint, **kwargs):
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        return self.session.request(method, url, **kwargs)

    def delete(self, endpoint, **kwargs):
        return self._make_request("DELETE", endpoint, **kwargs)

    def get(self, endpoint, **kwargs):
        return self._make_request("GET", endpoint, **kwargs)

    def post(self, endpoint, **kwargs):
        return self._make_request("POST", endpoint, **kwargs)

    def put(self, endpoint, **kwargs):
        return self._make_request("PUT", endpoint, **kwargs)


def get_env(var_name):
    value = os.getenv(var_name)
    if value is None:
        raise ValueError(f"Environment variable '{var_name}' is not set.")
    return value


def get_portainer_data(client, endpoint):
    response = client.get(endpoint)
    if response.status_code == 200:
        return response.json()
    else:
        raise ValueError(f"Failed to retrieve Portainer {endpoint}: Status code {response.status_code}")


def read_stack(path):
    try:
        with open(path, "r") as file:
            return file.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"The file '{path}' was not found.")
    except Exception as e:
        raise RuntimeError(f"An unexpected error occurred while reading '{path}': {e}")


def read_terraform_output(path):
    try:
        with open(path, "r") as file:
            return json.load(file)
    except FileNotFoundError:
        raise FileNotFoundError(f"The Terraform configuration file '{path}' was not found.")
    except json.JSONDecodeError:
        raise ValueError(f"The Terraform configuration file '{path}' is not valid JSON.")
    except Exception as e:
        raise RuntimeError(f"An unexpected error occurred while reading '{path}': {e}")


def deploy_or_update_stack(portainer, portainer_stacks, endpoint, service, service_file):
    action = None
    existing_stack = next((stack for stack in portainer_stacks if stack["EndpointId"] == endpoint["Id"] and stack["Name"] == service), None)

    if existing_stack:
        print(f"'{service}' exists on endpoint '{endpoint['Name']}', updating...")
        response = portainer.put(
            f"stacks/{existing_stack['Id']}",
            json={"prune": True, "pullImage": True, "stackFileContent": service_file},
            params={"endpointId": endpoint["Id"]},
        )
        action = "updated"
    else:
        print(f"'{service}' does not exist on endpoint '{endpoint['Name']}', deploying...")
        response = portainer.post(
            "stacks/create/standalone/string",
            json={"name": service, "stackFileContent": service_file},
            params={"endpointId": endpoint["Id"]},
        )
        action = "deployed"

    if response.status_code == 200:
        print(f"Successfully {action} Portainer stack '{service}' on endpoint '{endpoint['Name']}'.")
    else:
        raise ValueError(f"Failed to {action} Portainer stack '{service}' on endpoint '{endpoint['Name']}': Status code {response.status_code}")


def should_deploy_stack(endpoint, service, terraform_output):
    return service not in terraform_output or service in terraform_output and endpoint['Name'] in terraform_output[service]

def main():
    if len(sys.argv) != 3:
        raise ValueError("Usage: portainer.py <service> <terraform_output>")

    service = sys.argv[1]
    service_file = read_stack(service)
    terraform_output = sys.argv[2]
    terraform_output_file = read_terraform_output(terraform_output)

    portainer = APIClient(
        f"{get_env('PORTAINER_URL')}/api",
        headers={
            "Content-Type": "application/json",
            "X-API-Key": get_env("PORTAINER_API_TOKEN"),
        },
    )

    portainer_endpoints = get_portainer_data(portainer, "endpoints")
    portainer_stacks = get_portainer_data(portainer, "stacks")

    for endpoint in portainer_endpoints:
        try:
            if should_deploy_stack(endpoint, service, terraform_output_file):
                deploy_or_update_stack(portainer, portainer_stacks, endpoint, service, service_file)
            else:
                print(f"Skipping deployment for endpoint '{endpoint['Name']}' as per Terraform output.")
        except Exception as e:
            print(f"Error processing endpoint '{endpoint['Name']}': {e}", file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Exception: {e}", file=sys.stderr)
        sys.exit(1)
