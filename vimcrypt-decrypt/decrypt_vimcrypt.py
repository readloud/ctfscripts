#!/usr/bin/env python3

import sys

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} [file] [first 8 bytes]")
    sys.exit(1)

with open(sys.argv[1], 'rb') as f:
    data = f.read()

keystream = [x^ord(y) for x,y in zip(data[28:36],sys.argv[2])]

num_blocks = len(data[28:]) // 8 + 1
output = ""
for i in range(num_blocks):
    output += ''.join([chr(x^y) for x,y in zip(data[i*8+28:i*8+36],keystream)])

print(output)
