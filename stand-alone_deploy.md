# sugo单机版部署
 
1.环境初始化

    将下载好的安装包解压到 当前用户目录

    tar -zxf stand-alone_deploy.tar.gz -C ~
    cd ~/stand-alone_deploy
    mkdir -p /opt/apps
    yum install -y wget openssh-clients vim 
    ./init_centos6.sh -hostname test01.sugo.vm
    source /etc/profile

    测试
    java -version

    vi /etc/hosts
    最底下添加ip和hostname
        192.168.233.128 test01.sugo.vm

    建立两个目录用来保存各个服务的日志
    这里需要通过df -h 查看客户的机器情况，看哪个目录容量比较大，
    如果/目录下的容量较小，不能直接创建/data1和/data2，而应该创建符号连接 ln -s /创建的目录绝对路径 /
    当前假设/根目录容量够大

    mkdir /data1
    mkdir /data2

    

    
    
    
    
2.安装postgres数据库

    创建一个  postgres 用户

    adduser postgres
    passwd postgres
    (密码自己记住)

    tar -zxf ~/stand-alone_deploy/postgresql-9.5.4-1-linux-x64-binaries.tar.gz -C /opt/apps/

    cd /opt/apps
    mv pgsql postgres_sugo
    mkdir -p /data1/postgres/data
    mkdir -p /data1/postgres/log
    chown -f postgres:postgres /opt/apps/postgres_sugo/*
    chown -R postgres:postgres /data1/postgres

    //切换用户是为了登录postgres数据库
    su - postgres

    //初始化postgres数据库
    /opt/apps/postgres_sugo/bin/initdb --no-locale -E UTF-8 -D /data1/postgres/data
    //访问权限设置
    echo 'host    all   all         0.0.0.0/0          md5' >> /data1/postgres/data/pg_hba.conf
    //启动
    /opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log start
    //设置密码和端口号
    /opt/apps/postgres_sugo/bin/psql -d postgres -U postgres -p 5432 -c "ALTER USER postgres PASSWORD '123456' ;" 

    //登录
    /opt/apps/postgres_sugo/bin/psql
    //创建两个数据库 用于存储其它服务（astro/druid）的数据
    create database  astro_sugo with owner = postgres encoding = UTF8;
    create database  druid with owner = postgres encoding = UTF8;
    输入 \l 查看是否创建好两个数据库 druid  astro_sugo
    //创建好后 退出postgres数据库    用 ctrl+d 即可退出

    修改配置文件:

    cd /data1/postgres/data
    vi postgresql.conf (把里面全部内容替换成以下内容)

    datestyle='iso, mdy'
    default_text_search_config='pg_catalog.english'
    dynamic_shared_memory_type=posix
    lc_messages='C'
    lc_monetary='C'
    lc_numeric='C'
    lc_time='C'
    listen_addresses='0.0.0.0'
    log_timezone='PRC'
    max_connections=100
    port=5432
    shared_buffers=128MB
    unix_socket_directories = '/tmp'

    重启数据库

    /opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log restart

    以上为安装postgres数据库!
    exit 退出当前用户回到root用户

3.安装redis

    yum remove -y epel-release

    安装gcc编译器
    yum install -y gcc g++-c++

    cd /opt/apps
    tar -zxf ~/stand-alone_deploy/redis-3.0.7.tar.gz -C /opt/apps/
    mv redis-3.0.7 redis_sugo
    cd redis_sugo

    make

    mkdir /data1/redis

    vi redis.conf

    添加内容

    bind 0.0.0.0
    daemonize yes
    port 6379
    dir /data1/redis
    pidfile /opt/apps/redis_sugo/redis.pid

    chown -R root:root /opt/apps/redis_sugo

    启动
    /opt/apps/redis_sugo/src/redis-server /opt/apps/redis_sugo/redis.conf
    检查是否启动
    ./src/redis-cli
    127.0.0.1:6379>   出现这样证明启动成功

4.安装zookeeper


    cd /opt/apps/
    tar -zxf ~/stand-alone_deploy/zookeeper-3.4.8.tar.gz -C /opt/apps/
    mv zookeeper-3.4.8 zookeeper_sugo

    mkdir -p /data1/zookeeper/dataLog
    mkdir -p /data1/zookeeper/data

    echo 1 >> /data1/zookeeper/data/myid

    cd /opt/apps/zookeeper_sugo/conf

    cp zoo_sample.cfg zoo.cfg
    grep '^[[:space:]]*dataDir' /opt/apps/zookeeper_sugo/conf/zoo.cfg | sed -e 's/.*=//'


    vi zoo.cfg        (全部内容替换成以下内容)

    clientPort=2181
    syncLimit=5
    autopurge.purgeInterval=24
    maxClientCnxns=800
    dataDir=/data1/zookeeper/data
    dataLogDir=/data1/zookeeper/dataLog
    initLimit=10
    maxSessionTimeout=120000
    tickTime=2000
    autopurge.snapRetainCount=100
    server.1=192.168.233.128:2888:3888

    chown -R root:root /opt/apps/zookeeper_sugo

    启动
    /opt/apps/zookeeper_sugo/bin/zkServer.sh start


    主机在云平台会因环境变量问题而需要创建脚本启动

    创建脚本

    vim sugo_zookeeper_server.sh

    export JAVA_HOME=/usr/local/jdk18
    /opt/apps/zookeeper_sugo/bin/zkServer.sh start


    chmod 755 sugo_zookeeper_server.sh
    ./sugo_zookeeper_server.sh
    

    
5.安装kafka

    cd /opt/apps/
    tar -zxf ~/stand-alone_deploy/kafka_2.10-0.10.0.0.tgz -C /opt/apps/
    mv kafka_2.10-0.10.0.0 kafka_sugo

    cd /opt/apps/kafka_sugo

    修改配置文件

    vi config/server.properties

    zookeeper.connect=192.168.233.128:2181/kafka
    log.dirs=/data2/kafka/data

    mkdir -p /data2/kafka/data

    chown -R root:root /opt/apps/kafka_sugo

    启动:
    bin/kafka-server-start.sh config/server.properties

    或者
    启动在后台
    nohup /opt/apps/kafka_sugo/bin/kafka-server-start.sh config/server.properties > /opt/apps/kafka_sugo/kafka.log 2>&1 &

    检查:
    ps -ef |grep kafka
    
6.安装gateway

    cd /opt/apps/
    yum install -y libjpeg libpng freetype fontconfig
    tar -zxf ~/stand-alone_deploy/nginx-clojure-0.4.4.tar.gz -C /opt/apps/
    mv nginx-clojure-0.4.4 gateway_sugo
    export JAVA_HOME=/usr/local/jdk18
    cd gateway_sugo/

    vi libs/kafka.properties
    bootstrap.servers=192.168.233.128:9092 (单机版的只有一个ip要修改成自己的ip)

    chown -R root:root /opt/apps/gateway_sugo

    启动:
    /opt/apps/gateway_sugo/nginx-linux-x64

    测试:
    查看80端口起来了没有
    netstat -ntlp | grep 80
    或者打开网页查看
    http://192.168.233.128:80


    主机在云平台会因环境变量问题而需要创建脚本启动

    vi start.sh 

    #!/bin/bash
    export JAVA_HOME=/usr/local/jdk18
    export PATH=$JAVA_HOME/bin:$PATH
    ./nginx-linux-x64

    chmod +x start.sh
    
7.安装druid

    cd /opt/apps/
    tar -zxf ~/stand-alone_deploy/druid-1.0.0-bin.tar.gz -C /opt/apps/
    mv druid-1.0.0 druidio_sugo


    mkdir -p /opt/apps/druidio_sugo/var/druid/pids/
    mkdir /opt/apps/druidio_sugo/log
    mkdir -p /data1/druid/storage
    mkdir -p /data1/druid/indexing-logs
    mkdir -p /data1/druid/task
    mkdir -p /data1/druid/segment-cache

    修改配置文件：

    cd /opt/apps/druidio_sugo/conf/druid

    vi broker/jvm.config

    修改
    -Djava.io.tmpdir=/data1/druid/task
    添加
    -Dlog.file.path=/data1/druid/logs
    -Dlog.file.type=broker

    vi broker/runtime.properties

    修改
    druid.host=192.168.233.128

    vi _common/common.runtime.properties


    druid.license.signature=48710FA3F1CDBA39DD3D7589262F2D066767C05CDF6AF1006D5B4B77A62063111DE60AA0BD309BF3
    druid.emitter.composing.emitters=["logging"]
    (上面两条添加到配置文件的最后面) 
    druid.zk.service.host=192.168.233.128
    druid.metadata.storage.connector.connectURI=jdbc:postgresql://192.168.233.128:5432/druid
    druid.metadata.storage.connector.user=postgres
    druid.metadata.storage.connector.password=123456
    druid.storage.type=local     (去掉注释)
    druid.storage.storageDirectory=/druid/segments      (去掉注释) 并修改druid.storage.storageDirectory=/data1/druid/indexing-logs
    druid.storage.type=hdfs  注释掉
    druid.indexer.logs.type=hdfs        注释掉
    druid.storage.storageDirectory=/druid/segments   注释掉
    druid.indexer.logs.directory=/druid/indexing-logs     注释掉
    com.metamx.metrics.JvmMonitor [] 搜索删掉 方括号里面的全部删掉
    druid-kafka-eight   搜索删掉,注意,双引号和逗号也要删掉


    vi coordinator/jvm.config

    修改
    -Djava.io.tmpdir=/data1/druid/task
    最底下添加
    -Dlog.file.path=/data1/druid/logs
    -Dlog.file.type=coordinator

    mkdir -p /data1/druid/task

    vi coordinator/runtime.properties

    druid.host=192.168.233.128

    vi historical/jvm.config

    修改
    -Djava.io.tmpdir=/data1/druid/task
    底下添加
    -Dlog.file.path=/data1/druid/logs
    -Dlog.file.type=historical

    vi historical/runtime.properties

    修改
    druid.host=192.168.233.128
    druid.processing.buffer.sizeBytes=268435456
    druid.segmentCache.locations=[{"path":"/data1/druid/segment-cache","maxSize":130000000000}]
    添加
    druid.historical.segment.type=lucene
    druid.lucene.query.groupBy.defaultStrategy=v2
    druid.processing.numMergeBuffers=3
    druid.lookup.lru.cache.maxEntriesSize=20
    druid.lookup.lru.cache.expireAfterWrite=3600
    druid.lookup.lru.cache.expireAfterAccess=3600
    druid.lucene.query.select.maxResults=100000

    vi middleManager/jvm.config

    修改
    -Djava.io.tmpdir=/data1/druid/task
    添加
    -Dlog.file.path=/data1/druid/logs
    -Dlog.file.type=middleManager
    -Dlog.configurationFile=/opt/apps/druidio_sugo/conf/druid/_common/log4j2-default.xml

    vi middleManager/runtime.properties

    修改
    druid.host=192.168.233.128
    druid.indexer.runner.javaOpts=-server -Xmx2g -XX:MaxDirectMemorySize=2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager
    druid.indexer.task.baseTaskDir=/data1/druid/task/base
    druid.processing.buffer.sizeBytes=268435456

    vi overlord/jvm.config

    修改
    -Djava.io.tmpdir=/data1/druid/task
    添加
    -Dlog.file.path=/data1/druid/logs
    -Dlog.file.type=overlord

    vi overlord/runtime.properties

    修改
    druid.host=192.168.233.128


    vi overlord/supervisor.properties

    修改
    supervisor.kafka.zkHost=192.168.233.128:2181/kafka
    supervisor.kafka.replication=1
    supervisor.segmentGranularity=DAY
    supervisor.io.taskDuration=PT86400S 
    supervisor.io.useEarliestOffset=true

    cd /opt/apps/druidio_sugo/bin

    chown -R root:root /opt/apps/druidio_sugo


    创建启动脚本

    vim start-all.sh


    #!/usr/bin/env bash
    usage="Usage: start-all.sh"
    CUR_DIR=$(cd `dirname $0`; pwd)
    for nodeType in broker historical coordinator overlord middleManager;
    do
       sh $CUR_DIR/node.sh $nodeType start
    done




    这个是关闭脚本

    vim stop-all.sh

    #!/usr/bin/env bash
    usage="Usage: stop-all.sh"
    CUR_DIR=$(cd `dirname $0`; pwd)
    for nodeType in broker historical coordinator overlord middleManager;
    do
       sh $CUR_DIR/node.sh $nodeType stop
    done


    chmod 755 ./st*
    mkdir -p var/druid/pids

    启动
       cd /opt/apps/druidio_sugo
       ./bin/start-all.sh

    
    
    
8.安装astro

    cd /opt/apps
    tar -zxf ~/stand-alone_deploy/sugo-analytics-TSA.tar.gz -C /opt/apps/
    mv sugo-analytics astro_sugo
    useradd astro 
    cd /opt/apps/astro_sugo/analytics
    cp ~/stand-alone_deploy/config.js config.js

    vim config.js

    collectGateway: 'http://192.168.233.128'
    websdk_app_host: '192.168.233.128:8000'
    redis.host: '192.168.233.128'
    db.host: '192.168.233.128'
    db.database: 'astro_sugo',
    druid.host: '192.168.233.128:8082
    supervisorHost: 'http://192.168.233.128:8090'
    lookupHost: 'http://192.168.233.128:8081'
    zookeeperHost: '192.168.233.128:2181/kafka'
    kafkaServerHost: '192.168.233.128:9092

    chown -R root:root /opt/apps/astro_sugo

    创建数据存储目录：
    mkdir -p /data1/astro/log
    启动：
    cd /opt/apps/astro_sugo/analytics
    ./cmds/run

    前端登录账号:admin
    密码:admin123456
