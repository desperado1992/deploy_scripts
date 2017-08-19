#!/bin/bash
#$1 -- ambari-server的IP

baseurl=$1
initurl=$baseurl/deploy_scripts/centos6/ambari-server

cat ip.txt|while read line;
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
	"*]#*" { send "wget $initurl/init_centos6.sh\n" }
	"*]#*" { send "chmod 755 init_centos6.sh\n" }
	"*]#*" { send "./init_centos6.sh\n" }
	"*]#*" { send "rm -rf init_centos6.sh\n" }
	"*]#*"
	}
		expect "*]#*"
	send "wget $initurl/init_centos6.sh\n"
		expect "*]#*" 
	send "chmod 755 init_centos6.sh\n"
		expect "*]#*" 
	send "./init_centos6.sh\n"
		expect "*]#*" 
	send "rm -rf init_centos6.sh*\n"
		expect "*]#*"
EOF
done
