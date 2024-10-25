import sys
from flask import Flask, Response

app = Flask(__name__)

pld = sys.argv[1]

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def index(path=None):
    return pld, 200, {'Content-Type': 'text/javascript', 'access-control-allow-origin': '*', 'access-control-allow-credentials': 'true', 'access-control-allow-headers': 'x-requested-with'}

if __name__ == '__main__':
    app.run(host="0.0.0.0")