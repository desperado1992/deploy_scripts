#!/bin/bash

journalnode_stat="STARTEDSTARTEDSTARTED"
http_port=$1
server_IP=$2
cluster_name=$3
pw1=$4
baseurl=$5

#pw=`cat ../ambari-server/ip.txt | sed -n "1p" |awk '{print $2}'`

if [ "$1" = "-h" ] || [ "$1" = "-help" ];then
    echo 'usage : ./install $http_port $server_IP $cluster_name $server_password'
    exit
fi

sort ../ambari-server/host > ../ambari-agent/host

namenode1=`cat ../ambari-agent/host | sed -n "1p" |awk '{print $2}'`
namenode2=`cat ../ambari-agent/host | sed -n "2p" |awk '{print $2}'`
datanode1=`cat ../ambari-agent/host | sed -n "3p" |awk '{print $2}'`

sed -i "s/test1.sugo.vm/${namenode1}/g" host_until_hdfs.json
sed -i "s/test2.sugo.vm/${namenode2}/g" host_until_hdfs.json
sed -i "s/test3.sugo.vm/${datanode1}/g" host_until_hdfs.json

sed -i "s/test1.sugo.vm/${namenode1}/g" host_after_hdfs.json
sed -i "s/test2.sugo.vm/${namenode2}/g" host_after_hdfs.json
sed -i "s/test3.sugo.vm/${datanode1}/g" host_after_hdfs.json

sed -i "s/test1.sugo.vm/${namenode1}/g" host_hdfs.json
sed -i "s/test2.sugo.vm/${namenode2}/g" host_hdfs.json
sed -i "s/test3.sugo.vm/${datanode1}/g" host_hdfs.json

sed -i "s/test1.sugo.vm/${namenode1}/g" changed_configuration/astro-site.xml
sed -i "s/test1.sugo.vm/${namenode1}/g" changed_configuration/common.runtime.xml

#判断httpd服务是否已启动
http_service=`netstat -ntlp | grep $http_port | grep httpd`
if [ "$http_service" = "" ];then
echo "service http not running, please start it first!"
exit
fi

#判断ambari-server是否已经启动，如果没有，则等待启动完成
ambari=`netstat -ntlp | grep 8080`
while [ "$ambari" = "" ]
do
  ambari=`netstat -ntlp | grep 8080`
  if [ "$ambari" = "" ];then
    echo "waiting for ambari-server to start~~~"
    sleep 1
    continue
  else
    break
  fi
done

#创建集群、更新基础url，安装注册ambari-agent
./install_cluster.sh $http_port $server_IP $cluster_name
sleep 5

#重启ambari
#ambari-server restart

#安装hdfs及之前的服务
python install_service.py $server_IP $cluster_name host_until_hdfs.json
sleep 15 

  #判断hdfs是否已经安装，如果没有则等待安装完成
  hdfs_dir="/opt/apps/hadoop_sugo"
  while [ ! -d "$hdfs_dir" ]
  do
    hdfs_dir="/opt/apps/hadoop_sugo"
    if [ ! -d "$hdfs_dir" ];then
      echo "waiting for hdfs to be installed~~~"
      sleep 3
      continue
    else
      break
    fi
  done

 #启动hdfs及之前的服务
 echo "starting service postgres, redis, zookeeper and hdfs~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
 python start_service.py $server_IP $cluster_name host_until_hdfs.json
 sleep 10
 
  #判断所有journalnode是否都已经启动
  while true;do
  curl -u admin:admin -H "X-Requested-By: ambari" -X GET "http://$server_IP:8080/api/v1/clusters/$cluster_name/components/?ServiceComponentInfo/category=SLAVE&fields=ServiceComponentInfo/service_name,host_components/HostRoles/display_name,host_components/HostRoles/host_name,host_components/HostRoles/state,host_components/HostRoles/maintenance_state,host_components/HostRoles/stale_configs,host_components/HostRoles/ha_state,host_components/HostRoles/desired_admin_state,&minimal_response=true&_=1499937079425" > slave.json
  python slave.py slave.json > slave.txt
  state=`sed ':a;N;$!ba;s/\n//g' slave.txt`
    if [ "$state" = "$journalnode_stat" ];then
      # hdfs初始化
      echo "formating hdfs~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      #创建pg数据库并格式化hdfs
      ./pgdb_hdfsformat.sh $pw1 $server_IP $cluster_name
      break
    else
      sleep 2
          echo "waiting for journalnode to start~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      continue
    fi
  done

#安装hdfs之后得所有服务
python install_service.py $server_IP $cluster_name host_after_hdfs.json
sleep 10

#判断astro是否已经安装完成
/usr/bin/expect <<-EOF
set timeout 100000
spawn ssh $namenode1
                expect "*]#*"
          send "wget $baseurl/deploy_scripts/centos6/service/test_astro.sh\n"
                expect "*]#*"
          send "chmod 755 test_astro.sh \n"
                expect "*]#*"
          send "./test_astro.sh \n"
                expect "*]#*"
          send "rm -rf test_astro.sh \n"
                expect "*]#*"
EOF
#  astro_dir="/opt/apps/astro_sugo"
#  while [ ! -d "$astro_dir" ]
#  do
#    astro_dir="/opt/apps/astro_sugo"
#    if [ ! -d "$astro_dir" ];then
#      echo "waiting for astro to be installed~~~"
#      sleep 2
#      continue
#    else
#      break
#    fi
#  done



 #启动所有服务
python start_service.py $server_IP $cluster_name host_after_hdfs.json
