#!/bin/bash

# Code extracted and updated a bit from http://mail-archives.apache.org/mod_mbox/hive-user/202112.mbox/raw/%3Cb7dc08c1-dcaa-fe4d-f1e0-77ed0aab72a1%40rxd.hu%3E/

# List jars that are affected by log4j 2 security issue and print them in log4j_jars.txt
pat=org/apache/logging/log4j/core/lookup/JndiLookup.class mc=org/apache/logging/log4j/core/pattern/MessagePatternConverter.class && find / -name '*.jar'|xargs -n1 -IJAR unzip -t JAR |fgrep -f <(echo "$pat";echo 'Archive:')|grep -B1 "$pat"|grep '^Archive:'|cut -d '/' -f2-|xargs -n1 -IJAR bash -c 'unzip -p JAR $mc|md5sum|paste - <(echo JAR >> log4j_jars.txt )'|fgrep -vf <(echo 374fa1c796465d8f542bb85243240555 )

# Take each line of the file and remove the affected JndiLookup.class
echo 'Removing log4j2 class files affected by a security issue...'
cat log4j_jars.txt | xargs -t -I % sh -c 'zip -q -d % org/apache/logging/log4j/core/lookup/JndiLookup.class'
