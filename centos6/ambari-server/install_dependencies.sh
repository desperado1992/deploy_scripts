#!/bin/bash

cat host >> /etc/hosts

cat ip.txt |while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`

/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
    expect {
    "*yes/no*" { send "yes\n"
    expect "*assword:" { send "$pw\n" } }
    "*assword:" { send "$pw\n" }
        "*]#*"
    { send "yum install -y wget ntp openssh-clients\n" }
        "*]#*"
    { send "service ntpd start\n" }
        "*]#*"
    }
        expect "*#*"
    send "yum install -y wget ntp openssh-clients\n"
        expect "*]#*"
    send "service ntpd start\n"
        expect "*]#*"
EOF
done
