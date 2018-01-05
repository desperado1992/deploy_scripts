#!/usr/bin/env bash

baseurl=$1

if [ -d "/opt/apps/druidio_sugo" ];then
    wget $baseurl/hadoop_conf/hdfs-site.xml -O /opt/apps/druidio_sugo/conf/druid/_common/hdfs-site.xml
    wget $baseurl/hadoop_conf/core-site.xml -O /opt/apps/druidio_sugo/conf/druid/_common/core-site.xml
fi