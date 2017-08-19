#!/bin/bash

function print_usage(){
  echo "Usage: start [-options]"
  echo " where options include:"
  echo "     -help                    帮助文档"
  echo "     -http_port <port>        http服务端口号"
  echo "     -ambari_ip <ip>          ambari-server所在主机的IP"
  echo "     -hostname <hostname>     暂不支持在此脚本内修改，此处不添加该参数或设定参数为skip_hostname。如需修改可通过脚本hostname.sh"
  echo "     -skip_http <skip_http>   不安装yum源服务"
  echo "     -skip_createdir <skip_createdir>   不创建元数据存储目录"
  echo "     -skip_ssh <skip_ssh>     不安装ssh免密码"
  echo "     -skip_jdk <skip_jdk>     不安装jdk"
}

#cd `dirname $0`
http_port=0
ambari_ip=""
hostname="skip_hostname"
skip_http=0
skip_createdir=0
skip_ssh=0
skip_jdk=0

while [[ $# -gt 0 ]]; do
    case "$1" in
           -help)  print_usage; exit 0 ;;
       -http_port) http_port=$2 && shift 2;;
       -ambari_ip) ambari_ip=$2 && shift 2;;
       -hostname) hostname=$2 && shift 2;;
       -skip_http) skip_http=1 && shift ;;
       -skip_createdir) skip_createdir=1 && shift ;;
       -skip_ssh) skip_ssh=1 && shift ;;
       -skip_jdk) skip_jdk=1 && shift ;;
    esac
done

if [ "$http_port" -eq 0 ]
  then
    echo "-http_port is required!"
    exit 1
fi

if [ "$ambari_ip" = "" ]
  then
    echo "-ambari_ip is required!"
    exit 1
fi

if [ "$hostname" = "" ] && [ $skip_http -eq 0 ] && [ $skip_jdk -eq 0 ] && [ $skip_createdir -eq 0 ] && [ "$skip_ssh" -eq 0 ]
  then
    echo "-hostname is required!"
    exit 1
fi

#安装yum源
if [ $skip_http -eq 0 ]
  then
    ./sugo_yum_inst.sh $http_port
    echo "~~~~~~~~~~~~yum installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~~http server for sugo_yum skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#修改astro包名
astro_package=`ls /var/www/html/sugo_yum/SG/centos6/1.0/ | grep sugo-analytics*`
mv $astro_package sugo-analytics-SAAS.tar.gz

#http_port=`cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`
baseurl=http://$ambari_ip:$http_port/sugo_yum

#相关依赖并开启ntpd
./install_dependencies.sh
echo "~~~~~~~~~~~~directory created~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#分发hosts文件
if [ $skip_ssh -eq 0 ]
  then
    ./scp_hosts.sh
    echo "~~~~~~~~~~~~hosts file success coped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~~scp hosts file skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#创建元数据存储目录
if [ $skip_createdir -eq 0 ]
  then
    ./create_datadir.sh ambari-server/ip.txt
    echo "~~~~~~~~~~~datadir success created~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~create datadir skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#初始化主机
./init_process.sh $baseurl
echo "~~~~~~~~~~~init centos ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

#修改ambari-server节点的hostname
if [ $skip_hostname != "skip_hostname" ]
  then
    hostname $hostname
    sed -i "s/HOSTNAME=.*/HOSTNAME=${hostname}/g" /etc/sysconfig/network
    #按照ip.txt内的域名修改其它所有节点的hostname
    ./hostname.sh ip.txt
    cat new_hostname >> /etc/hosts
    echo "~~~~~~~~~~~hostname success changed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else 
    echo "~~~~~~~~~~~change hostname skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#配置ssh免密码登录
if [ $skip_ssh -eq 0 ]
  then
    ./ssh-inst.sh $baseurl ip.txt
    echo "~~~~~~~~~~~ssh-password-less configured~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~ssh-password-less skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#安装jdk
if [ $skip_jdk -eq 0 ]
  then
    ./jdk-inst.sh $baseurl ip.txt
    echo "~~~~~~~~~~~jdk success installed~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    echo "~~~~~~~~~~~jdk install skipped~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi

#安装ambari-server
./ambari_server_inst.sh $baseurl

