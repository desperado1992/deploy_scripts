#!/bin/bash


#判断hostname是否符合规则
host_name1=`hostname | cut -d \. -f 3`
host_name2=`hostname | cut -d \. -f 4`

if [ $host_name1 = "" ];then
  echo "please alter hostname~~~~~~~~~~~~~~~~~~~~~~~~"
  exit 1
fi

if [ ! -z $host_name2 ];then
  echo "please alter hostname~~~~~~~~~~~~~~~~~~~~~~~~"
  exit 1
fi


#判断数据存储目录是否已存在
data1_dir="/data1"
data2_dir="/data2"

if [ -d $data1_dir ] || [ -d $data2_dir ];then
  echo "数据目录/data1或/data2已创建，请确认该目录是否能够用于数据存储，如果可以，请在执行start.sh脚本时添加参数-skip_createdir skip_createdir并手动确认/data1和/data2都已创建"
  exit 1
fi


