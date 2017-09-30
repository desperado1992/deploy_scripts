#!/bin/bash

local_hn=`hostname`

#修改本机/etc/hosts文件
cat host | while read line;do
ip=`echo $line|awk '{print $1}'`
hn=`echo $line|awk '{print $2}'`

hn_exists=`cat /etc/hosts | grep $ip`
  if [ "$hn_exists" != "" ];then
    sed -i "s/`cat /etc/hosts |grep "$ip " |grep -v "#" |awk '{print $2}'`/$hn/" /etc/hosts
  else
    cat "$ip $hn" >> /etc/hosts
  fi
done

#分发本机hosts文件到其它主机
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
