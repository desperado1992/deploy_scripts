#!/bin/bash

baseurl=$1
conf_file=$2
init_url=$baseurl/deploy_scripts/centos6/ambari-server


./jdk.sh $baseurl

cat $conf_file | while read line;
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
        { send "wget $init_url/jdk.sh\n" }
                "*]#*"
        send "chmod 755 jdk.sh\n"
                "*]#*"
        { send "./jdk.sh $baseurl\n" }
                "*]#*"
        { send "rm -rf jdk.sh*\n" }
                "*]#*"
        }
                expect "*]#*"
        send "chmod 755 jdk.sh\n"
                expect "*]#*"
        send "./jdk.sh $baseurl\n"
                expect "*]#*"
        send "rm -rf jdk.sh\n"
                expect "*]#*"
EOF
done
