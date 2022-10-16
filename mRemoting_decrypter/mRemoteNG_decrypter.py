#!/usr/bin/env python3

import base64
import hashlib
import re
import sys
from Cryptodome.Cipher import AES

if len(sys.argv) != 2 and len(sys.argv) != 3:
    print(f"[-] Usage: {sys.argv[0]} [confCons.xml] <password>\npassword will be mR3m if not given")
    sys.exit()

if len(sys.argv) == 2:
    master = b"mR3m"
else:
    master = sys.argv[2].encode()

try:
    with open(sys.argv[1], 'r') as f:
        conf = f.read()
except FileNotFoundError:
    print(f"[-] Unable to open {sys.argv[1]}")
    sys.exit()

mode = re.findall('BlockCipherMode="(\w+)"', conf)
if len(mode) !=1:
    print("[-] Warning - No BlockCipherMode detected")
elif mode[0] != 'GCM':
    print(f"[-] Warning - This script is for AES GCM Mode. {mode} detected")

nodes = re.findall('<Node .+/>', conf)
if len(nodes) > 0:
    print(f"[+] Found nodes: {len(nodes)}\n")
else:
    print("[-] Found no nodes")

for node in nodes:
    user = re.findall(' Username="(\w*)"', node)[0]
    enc = base64.b64decode(re.findall(' Password="([^ ]+)"', node)[0])
    salt = enc[:16]
    nonce = enc[16:32]
    cipher = enc[32:-16]
    tag = enc[-16:]
    key = hashlib.pbkdf2_hmac("sha1", master, salt, 1000, dklen=32)
    aes = AES.new(key, AES.MODE_GCM, nonce=nonce)
    aes.update(salt)
    try:
        password = aes.decrypt_and_verify(cipher, tag).decode()
    except ValueError:
        print(f'[-] Master password "{master.decode()}" failed to decrypt passwords.\n[*] Exiting.')
        sys.exit(1)
    print(f"Username: {user}\nPassword: {password}\n")
