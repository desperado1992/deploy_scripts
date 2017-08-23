#!/usr/bin/env bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                    帮助文档"
  echo "     -http_port <port>        http服务端口号"
  echo "     -ambari_ip <ip>          ambari-server所在主机的IP"
  echo "     -skip_datadir <skip_datadir>     不创建数据存储目录"
  echo "     -skip_ssh <skip_ssh>     不安装ssh免密码"
  echo "     -skip_jdk <skip_jdk>     不安装jdk"
}

#cd `dirname $0`
http_port=0
ambari_ip=""
skip_datadir=0
skip_ssh=0
skip_jdk=0

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -http_port) http_port=$2 && shift 2;;
       -ambari_ip) ambari_ip=$2 && shift 2;;
       -skip_datadir) skip_datadir=1 && shift ;;
       -skip_ssh) skip_ssh=1 && shift ;;
       -skip_jdk) skip_jdk=1 && shift ;;
    esac
done

if [ "$http_port" -eq 0 ]
  then
    echo "-http_port is required!"
    exit 1
fi

if [ "$ambari_ip" = "" ] && [ $skip_jdk -eq 0 ] && [ "$skip_ssh" -eq 0 ] [ "$skip_datadir" -eq 0 ]
  then
    echo "-ambari_ip is required!"
    exit 1
fi

baseurl=http://$ambari_ip:$http_port/sugo_yum
init_url=$baseurl/deploy_scripts/centos6/ambari-server

cat hosts |while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`
ipaddr=`echo $line|awk '{print $3}'`

echo "$ipaddr $hn" >> /etc/hosts

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
    }
        expect "*#*"
    send "yum install -y wget ntp openssh-clients\n"
        expect "*]#*"
EOF

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

/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $hn
        expect {
        "*yes/no*" { send "yes\n"
        expect "*assword:" { send "$pw\n" } }
        "*assword:" { send "$pw\n" }
                "*]#*"
        { send "wget $init_url/init_centos6.sh\n" }
                "*]#*"
        send "chmod 755 init_centos6.sh\n"
                "*]#*"
        { send "./init_centos6.sh\n" }
                "*]#*"
        { send "rm -rf init_centos6.sh*\n" }
                "*]#*"
        { send "service ntpd start\n" }
                "*]#*"
        }
                expect "*]#*"
        send "wget $init_url/init_centos6.sh\n"
                expect "*]#*"
        send "chmod 755 init_centos6.sh\n"
                expect "*]#*"
        send "./init_centos6.sh $baseurl\n"
                expect "*]#*"
        send "rm -rf init_centos6.sh\n"
                expect "*]#*"
        send "service ntpd start\n"
                expect "*]#*"
EOF
done

#创建数据存储目录
if [ $skip_datadir -eq 0 ]
  then
    ../ambari-server/create_datadir.sh ambari-agent/hosts
    echo "~~~~~~~~~~~datadir created~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~create_datadir skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi


#配置ssh免密码登录
if [ $skip_ssh -eq 0 ]
  then
    ../ambari-server/ssh-inst.sh $baseurl hosts
    echo "~~~~~~~~~~~ssh-password-less configured~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~ssh-password-less skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#安装jdk
if [ $skip_jdk -eq 0 ]
  then
    ../ambari-server/jdk-inst.sh $baseurl hosts
    echo "~~~~~~~~~~~jdk success installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~jdk install skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

cat ../ambari-server/ip.txt |while read line;
do
hn=`echo $line|awk '{print $1}'`
pw=`echo $line|awk '{print $2}'`

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
done
