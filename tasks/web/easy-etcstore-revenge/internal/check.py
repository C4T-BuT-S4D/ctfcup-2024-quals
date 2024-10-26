import requests
import json

class EtcdClient:
    def __init__(self, base_url="http://127.0.0.1:8080"):
        self.base_url = base_url
        self.token = None
        self.session = requests.Session()
    
    def set_token(self, token):
        print("Setting token:", token)
        self.token = token
        self.session.headers.update({"Authorization": self.token})

    def register(self, username, password):
        url = f"{self.base_url}/auth/register"
        data = {
            "username": username,
            "password": password
        }
        response = self.session.post(url, json=data)
        if response.status_code == 201:
            self.set_token(response.json())
            print("User registered successfully.")
        else:
            print(f"Error: {response.status_code}, {response.text}")

    def login(self, username, password):
        url = f"{self.base_url}/auth/login"
        data = {
            "username": username,
            "password": password
        }
        response = self.session.post(url, json=data)
        if response.status_code == 200:
            self.set_token(response.json())
            print(response.headers)
            print(self.session.cookies)
            print("Login successful.")
        else:
            print(f"Error: {response.status_code}, {response.text}")

    def store_key(self, key, value):
        url = f"{self.base_url}/data/{key}"
        data = value
        response = self.session.post(url, json=data)
        if response.status_code == 201:
            print("Data stored successfully.")
        else:
            print(f"Error: {response.status_code}, {response.text}")

    def get_key(self, key):
        url = f"{self.base_url}/data/{key}"
        response = self.session.get(url)
        if response.status_code == 200:
            print(f"Data for key '{key}': {response.json()}")
        else:
            print(f"Error: {response.status_code}, {response.text}")

    def list_keys(self):
        url = f"{self.base_url}/data"
        response = self.session.get(url)
        if response.status_code == 200:
            print("List of keys:", response.json())
        else:
            print(f"Error: {response.status_code}, {response.text}")

# Example usage
if __name__ == "__main__":
    client = EtcdClient()

    # Register a new user
    client.register("user1", "password1")

    # Log in with the user credentials
    client.login("user1", "password1")

    # Store some data
    client.store_key("sampleKey", "sampleValue123")

    # Retrieve the stored data
    client.get_key("sampleKey")

    # List all keys
    client.list_keys()
