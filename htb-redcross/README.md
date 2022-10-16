## Challenge

[RedCross](https://www.hackthebox.eu/home/machines/profile/162) from Hackthebox.eu

## Description

Performs a buffer overflow in iptctl binary.

## Reference

Originally published in blog posts: http://localhost:4000/2019/04/13/htb-redcross.html#path-3-bof-in-iptctl

## Dependencies

[python pwntools](https://github.com/Gallopsled/pwntools)

## Usage

Start `socat` listening linked to `iptctl` on RedCross and then run the script:

```
root@kali# python pwn_iptctl.py
[*] Attempting to connect
[+] Opening connection to 10.10.10.113 on port 9001: Done
[*] Switching to interactive mode
$ id
uid=0(root) gid=1000(penelope) egid=0(root) groups=0(root)
```
