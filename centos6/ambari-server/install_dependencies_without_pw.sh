#!/bin/bash


cat ip.txt |while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`
local_hn=`hostname`

if [ "$hn" != "$local_hn" ];then
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
    expect {
    "*yes/no*" { send "yes\n"
    expect "*~]#*" { send "\n" } }
    "*~]#*" { send "\n" }
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
fi
done