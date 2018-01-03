#!/bin/bash

#端口号--$1
http_port=$1

#ambari-server主机安装相关软件及http服务
yum install -y httpd

http_server=`ps -ef | grep httpd | grep -v "grep httpd"`
if [ "$http_server" = "" ];then
	yum install -y httpd
fi

#修改http端口号
sed -i "s/`cat /etc/httpd/conf/httpd.conf |grep "Listen " |grep -v "#" |awk '{print $2}'`/$http_port/" /etc/httpd/conf/httpd.conf

#创建软连接
cd ../..
yum_direct=`echo $(dirname $(pwd))`
ln -s $yum_direct /var/www/html/

#开启http服务
service httpd start
