## Description

If I know or can guess the first 8 bytes of a file encrypted with vimcrypt, I can get the next 56 bytes after that in plaintext as well. This script does that. It was used for [Kryptos](https://www.hackthebox.eu/home/machines/profile/183) from Hackthebox.eu

## Reference

Originally published in blog posts: https://0xdf.gitlab.io/2019/09/21/htb-kryptos.html
Theory for the attack from: https://dgl.cx/2014/10/vim-blowfish

## Usage

```
root@kali# ./decrypt_vimcrypt.py creds.txt rijndael
rijndael / bkVBL8Q9HuBSpj
```
