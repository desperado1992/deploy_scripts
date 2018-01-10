#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                          帮助文档"
  echo "     -http_port <port>              http服务端口号"
  echo "     -server_IP <server_IP>         ambari-server所在主机的IP"
  echo "     -cluster_name <name>           集群名称"
  echo "     -csv                           选择自定义csv格式的文件或按照默认来安装服务，默认时不填写该参数"
}

#cd `dirname $0`
http_port=80
server_IP=""
cluster_name=""
csv=""

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -http_port) http_port=$2 && shift 2;;
       -server_IP) server_IP=$2 && shift 2;;
       -cluster_name) cluster_name=$2 && shift 2;;
       -csv) csv=1 && shift ;;
    esac
done

#根据../ambari-server/host文件内的行数判断journalnode_stat的值
journalnode_stat=""
i=0
n=`cat ../ambari-server/host | wc -l`
while true;do
  if [ $i -lt $n ];then
    journalnode_stat=$journalnode_stat"STARTED"
	i=$[$i+1]
	continue
  else
    break
  fi
done

baseurl=http://$server_IP:$http_port/sugo_yum

#pw=`cat ../ambari-server/ip.txt | sed -n "1p" |awk '{print $2}'`

if [ "$http_port" -eq 0 ]
  then
    echo "-http_port is required!"
    exit 1
fi

if [ "$server_IP" = "" ]
  then
    echo "-server_IP is required!"
    exit 1
fi

if [ "$cluster_name" = "" ]
  then
    echo "-cluster_name is required!"
    exit 1
fi

#修改host文件并根据ascii码对hostname进行排序
cd ../ambari-server

rm -rf host1 host2
rm -rf ../ambari-agent/host

cat host | while read line;
do
ip1=`echo $line|awk '{print $1}'`
hn1=`echo $line|awk '{print $2}'`
echo "$hn1 $ip1" >> host1
done

sort host1 >> host2

cat host2 | while read line;
do
hn2=`echo $line|awk '{print $1}'`
ip2=`echo $line|awk '{print $2}'`
echo "$ip2 $hn2" >> ../ambari-agent/host
done

rm -rf host1 host2

cd -
#sort ../ambari-server/host > ../ambari-agent/host

if [ "$csv" = "" ];then
  cluster_host1=`cat ../ambari-agent/host | sed -n "1p" |awk '{print $2}'`
  cluster_host2=`cat ../ambari-agent/host | sed -n "2p" |awk '{print $2}'`
  cluster_host3=`cat ../ambari-agent/host | sed -n "3p" |awk '{print $2}'`

  sed -i "s/test1.sugo.vm/${cluster_host1}/g" hosts.json
  sed -i "s/test2.sugo.vm/${cluster_host2}/g" hosts.json
  sed -i "s/test3.sugo.vm/${cluster_host3}/g" hosts.json
fi

#获取namenode及astro所在主机并替换astro和druid的配置项
cd ../service/
rm -rf namenode_astro_host.txt
python get_host.py hosts.json namenode_astro_host.txt

namenode1=`cat namenode_astro_host.txt | grep "namenode1" | awk '{print $2}'`
namenode2=`cat namenode_astro_host.txt | grep "namenode2" | awk '{print $2}'`
astro_host=`cat namenode_astro_host.txt | grep "astro_host" | awk '{print $2}'`
redis_host=`cat namenode_astro_host.txt | grep "redis_host" | awk '{print $2}'`
postgres_host=`cat namenode_astro_host.txt | grep "postgres_host" | awk '{print $2}'`
gateway_host=`cat namenode_astro_host.txt | grep "gateway_host" | awk '{print $2}'`

rm -rf changed_configuration
cp -r changed_configurations changed_configuration
sed -i "s/test1.sugo.vm/${astro_host}/g" changed_configuration/astro-site.xml
sed -i "s/test2.sugo.vm/${gateway_host}/g" changed_configuration/astro-site.xml
sed -i "s/test3.sugo.vm/${postgres_host}/g" changed_configuration/astro-site.xml
sed -i "s/test4.sugo.vm/${redis_host}/g" changed_configuration/astro-site.xml
sed -i "s/test1.sugo.vm/${postgres_host}/g" changed_configuration/common.runtime.xml
cd -

#判断httpd服务是否已启动
http_service=`netstat -ntlp | grep $http_port | grep httpd`
if [ "$http_service" = "" ];then
echo "service http not running, please start it first!"
exit
fi

#判断ambari-server是否已经启动，如果没有，则等待启动完成
ambari=`netstat -ntlp | grep 8080`
printf "waiting for ambari-server to start"
x=0
while [ "$ambari" = "" ]
do
  ambari=`netstat -ntlp | grep 8080`
  if [ "$ambari" = "" ];then
    sleep 1
    x=$[$x+1]
    if [ $x -lt 60 ];then
        printf "."
        continue
    else
        echo -e "\n==========Timeout==========\nThe installation of Ambari-server failed, please check the configurations and run start.sh again!"
        exit 1
    fi
  else
    break
  fi
done
echo ""

#创建集群、更新基础url，安装注册ambari-agent
./install_cluster.sh $http_port $server_IP $cluster_name
sleep 5

#重启ambari
#ambari-server restart

#安装服务
python install_service.py $server_IP $cluster_name hosts.json
sleep 15 

#判断astro是否已经安装完成
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $astro_host
                expect "*]#*"
          send "wget $baseurl/deploy_scripts/centos6/service/pg_db_astro.sh\n"
                expect "*]#*"
          send "chmod 755 pg_db_astro.sh\n"
                expect "*]#*"
          send "./pg_db_astro.sh\n"
                expect "*]#*"
          send "rm -rf pg_db_astro.sh\n"
                expect "*]#*"
EOF

##copy hdfs-site.xml and core-site.xml to the directory of druid
#cat ../ambari-server/host |while read line;
#do
#hn=`echo $line|awk '{print $1}'`
#pw=`echo $line|awk '{print $2}'`
#local_hn=`hostname`
#
#/usr/bin/expect <<-EOF
#set timeout 100000
#spawn ssh $hn
#        expect {
#        "*yes/no*" { send "yes\n"
#        expect "*assword:" { send "$pw\n" } }
#        "*assword:" { send "$pw\n" }
#        "*~]#*" { send "\n"}
#        }
#                expect "*]#*"
#        send "wget $baseurl/deploy_scripts/centos6/service/druid_hadoop_conf.sh\n"
#                expect "*]#*"
#        send "chmod 755 druid_hadoop_conf.sh\n"
#                expect "*]#*"
#        send "./druid_hadoop_conf.sh $baseurl\n"
#                expect "*]#*"
#        send "rm -rf druid_hadoop_conf.sh\n"
#                expect "*]#*"
#EOF
#done

 #启动服务
python start_service.py $server_IP $cluster_name hosts.json
