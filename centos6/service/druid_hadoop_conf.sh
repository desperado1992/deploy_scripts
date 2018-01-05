#!/usr/bin/env bash

baseurl=$1

if [ -d "/opt/apps/druidio_sugo" ];then
    wget $baseurl/deploy_scripts/centos6/service/changed_configurations/hdfs-site.xml -O /opt/apps/druidio_sugo/conf/druid/_common/hdfs-site.xml
    wget $baseurl/deploy_scripts/centos6/service/changed_configurations/core-site.xml -O /opt/apps/druidio_sugo/conf/druid/_common/core-site.xml
fi