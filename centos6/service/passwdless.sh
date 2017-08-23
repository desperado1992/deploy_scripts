#!/bin/bash

#NameNode1 = $1
#passwd1 = $2
#NameNode2 = $3
#passwd2 = $4

#Namenode1上hdfs用户生成ssh秘钥对
ssh $1 "yum install -y expect"
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $1
	expect "*~]#*" { send "su - hdfs\n"
	expect "*~]\$*" { send "ssh-keygen -t rsa\n"
		expect "*id_rsa*"
	send "\n"
        expect "*passphrase):*"
	send "\n"
        expect "*again:*"
	send "\n"
		expect "*]\$*"}}
EOF

#Namenode2上hdfs用户生成ssh秘钥对，并将authorized_keys复制到NameNode1
ssh $3 "yum install -y expect"
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $3
	expect "*~]#*" { send "su - hdfs\n"
	expect "*~]\$*" { send "ssh-keygen -t rsa\n"
		expect "*id_rsa*"
	send "\n"
        expect "*passphrase):*"
	send "\n"
        expect "*again:*"
	send "\n"
		expect "*]\$*"
	send "cat /home/hdfs/.ssh/id_rsa.pub >> /home/hdfs/.ssh/authorized_keys\n"}}
		expect "*]\$*"
	send "exit\n"
		expect "*~]#*"
	send "scp /home/hdfs/.ssh/authorized_keys  $1:/home/hdfs/.ssh/\n"
		expect {
	"*yes/no*" { send "yes\n"
		expect "*assword:" { send "$2\n" } }
	"*assword:" { send "$2\n" } }
	
		expect "*~]\#*"
EOF

#NameNode1生成包含NameNode1和NameNode2的authorized_keys，且将其发送给NameNode2，赋予.ssh文件夹及其文件权限
ssh $1 "chown hdfs:hdfs /home/hdfs/.ssh/authorized_keys"
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $1
	expect "*~]#*" { send "su - hdfs\n"
		expect "*~]\$*" 
	send "cat /home/hdfs/.ssh/id_rsa.pub >> /home/hdfs/.ssh/authorized_keys\n"
		expect "*~]\$*"
	send "chmod 700 .ssh/\n"
        expect "*~]\$*"
	send "chmod 600 .ssh/*\n"
		expect "*~]\$*"
	send "exit\n"
		expect "*]#*"
	send "scp /home/hdfs/.ssh/authorized_keys root@$3:/home/hdfs/.ssh/\n"
		expect {
	"*yes/no*" { send "yes\n"
		expect "*assword:" { send "$4\n" } }
	"*assword:" { send "$4\n" } 
	"*]#*" { send "\n"}}
		expect "*]#*"}
EOF


#NameNode2赋予.ssh文件夹、文件权限，并验证免密码登录是否成功
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $3
	expect "*~]#*" { send "su - hdfs\n"
		expect "*~]\$*" 
	send "chmod 700 .ssh/\n"
        expect "*~]\$*"
	send "chmod 600 .ssh/*\n"
		expect "*~]\$*"
	send "ssh $1\n"
		expect  "*(yes/no)?"  
	send "yes\n"
		expect "*~]\$*"}
EOF

#验证NameNode1免密码登录到NameNode2是否成功
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $1
	expect "*~]#*" { send "su - hdfs\n"
		expect "*~]\$*" 
	send "ssh $3\n"
		expect  "*(yes/no)?"  
	send "yes\n"
		expect "*~]\$*"}
EOF
