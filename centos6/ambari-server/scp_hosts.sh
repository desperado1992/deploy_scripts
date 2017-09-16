#!/bin/bash

local_hn=`hostname`

cat ip.txt|while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`
if [ "$hn" != "$local_hn" ];then
    /usr/bin/expect <<-EOF
    set timeout 100000
    spawn scp -r /etc/hosts root@$hn:/etc/
    	expect {
    	"*yes/no*" { send "yes\n"
    	expect "*assword:" { send "$pw\n" } }
    	"*assword:" { send "$pw\n" }
    	"*]#*"	
    	}
    	expect "*]#*"
    EOF
fi
done
