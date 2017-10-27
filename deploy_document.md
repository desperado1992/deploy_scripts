# 集群部署文档 #

## 1 前期准备 ##
### 1.1 主机配置要求
建议机器最低配置（也可根据实际情况降低配置，但不建议这样做）
* CPU ：8核
* 内存：32g
* 磁盘：根据数据量而定，可用空间 > 数据量 * 3， 尽量不要用lvm和raid，否则会影响接入和查询性能，可挂载多个磁盘，提高并发
* 数量：3

系统要求： CentOS6.8（其他版本未测试）  
不能连接外网的，请搭好局域网CentOS yum源。  
机器数量较多时，建议搭建内部DNS服务器  
  
### 1.2 组件安装规划  
各组件在各主机上的分布如下：

Services| Components|test01.sugo.vm|test02.sugo.vm|test03.sugo.vm
-------|----------|----------|----------|----------
Ambari Metrics  |   Metrics Collector   |   √ | |
Ambari Metrics  |   Grafana | √ |  |
Ambari Metrics  |   Metrics Monitor | √ | √ | √	　	　
PostgresQL  |   Postgres server     |√	　	　	　
Redis	|Redis server   | √	　	　	　
Zookeeper	|ZooKeeper  Server  |√|√|√	　	　	　
HDFS	|Namenode   |√|√	　	　	　
HDFS	|Datanode   |√|√|√	　	　	　
HDFS	|ZKFailoverController   |√|√|	　	　	　
HDFS    |Journalnode    |√|√|√	　	　	　
Yarn    |Resourcemanager    |√|√	　	　	　
Yarn	|ProxyServer    |√	　	　	　
Yarn	|Nodemanager    |√	　	　	　
MapReduce	|History Server |   √	　	　	　
Kafka	|Kafka Broker   |||√	　	　	　
Druid	|Broker |√|√	　	　	　
Druid	|Historical ||√|√	　	　
Druid	|Overlord   |√|√	　	　	　
Druid	|MiddleManager  |√|√	　	　
Druid	|Coordinator    |√|√	　	　
Astro	|ASTRO UI   |√	　	　
OpenResty	|OpenResty Server   |√	　	　	　




## 2 Ambari-server安装 
做好主机规划并准备主机，配置静态IP，修改主机hostname，规划数据存储目录，如果是离线主机，需配置本地安装源库

注：  
hostname需设为二级域名，如：test01.sugo.vm  
创建sugo_yum源存放目录，上传（或下载）sugo_yum源  
解压缩yum源安装包
修改sugo_yum/deploy_scripts/centos6/ambari_server_inst/下的配置文件host和ip.txt文件
host文件为各主机ip与hostname的映射，ip.txt文件为ambari-server所在主机以外，其它所有主机的hostname+root用户密码  
对执行脚本赋予执行执行权限
启动启动脚本进行安装

```
cd {yum源存放目录}/sugo_yum/deploy_scripts/centos6/ambari-server
vi host
	192.168.10.1 test01.sugo.vm
		...
vi ip.txt
	test02.sugo.vm 123456
	test03.sugo.vm 123456  
		...

```

start.sh脚本的具体使用方法可通过./start -help查看
例：
```
./start.sh -ambari_ip 192.168.10.150 -skip_cluster_services
```

如果没有报错信息，则基本表明Ambari-server安装成功， Web UI默认端口8080，后面的应用（services）可通过脚本或界面进行安装
 



## 3 服务安装(脚本安装或Web安装选其一) ##

  服务(service)的安装可通过两种方式进行，目前建议主机注册、安装AMS通过web操作，其它服务可考虑脚本安装：  
#### 3.0 主机注册及Ambari Metrics安装  
按照界面提示操作即可  
参数：Grafana Admin Password：admin admin  

###### 脚本安装 ######  
通过http服务调用ambari的REST API来安装服务，安装较简单，速度较快，但配置相关属性时需仔细，脚本安装适合对Linux或Unix比较熟悉的人；  
###### Web安装
界面友好，但操作较为繁琐，安装时间较长    
    
### 3.1 脚本安装service

#### 3.1.1 准备：  
在安装服务（service）之前，需要做好集群组件安装规划，此部分在脚本自动化部署的上半部分已经准备好，将规划好的组件及主机信息转换格式，按照格式完成目录下的host_service.json文件  
修改脚本install.py内的base_url  
需修改的脚本或文件：  
```
deploy_scripts/service_inst/host_service.json  
deploy_scripts/service_inst/install.py

```

#### 3.1.2 安装服务
进入脚本目录deploy_scripts/service_inst/，启动安装脚本：
```
python install.py
```
  
  安装完成后，修改配置文件，配置NameNode1和NameNode2下的hdfs用户的免密码登录，保证HDFS的高可用，然后按照一定顺序启动服务  
  
需修改配置： 

Services| Files|Parameters|Value(example)|Alter|Attention
-------|----------|----------|----------|----------|----------
Postgres   |postgres-env|postgres.password | 123456| √	|
||       | port             | 15432 |      |√
Druid      |   common.runtime|druid.license.signature|建平提供| √	　	　
||      |druid.metadata.storage.connector.connectURI| jdbc:postgresql://dev220.sugo.net:15432/druid|√
|||druid.metadata.storage.connector.password|123456|√|	
OpenResty|openresty-site|redis_host|dev220.sugo.net|√|
Astro|astro-site|dataConfig.hostAndPorts|dev220.sugo.net:6379|√|
|||db.host|dev220.sugo.net|√|
|||db.password|123456|√|
|||db.port|15432|√|
|||redis.host|dev220.sugo.net|√|
|||site.collectGateway|http://dev220.sugo.net|√|
|||site.sdk_ws_url| ws://dev220.sugo.net:8887|√|
|||site.websdk_api_host|dev220.sugo.net:8000|√|
|||site.websdk_app_host|dev220.sugo.net:8000|√|
|||site.websdk_decide_host|dev220.sugo.net:8000|√|
|||site.file_server_secret| 暂时可随意填写|√|
|||site.file_server_token|暂时可随意填写|√|
|||site.file_server_url|暂时可随意填写|√|
AMS|ams-grafana-env|Grafana Admin Password|admin|√|


  


  配置NameNode1和NameNode2下的hdfs用户的免密码登录，启动配置脚本并带上参数（注：passwd为root用户密码）：  
  ```
  ./password-less-ssh-hdfs.sh $NN1 $passwd(NN1) $NN2 $passwd(NN2)
  例：./password-less-ssh-hdfs.sh test1.sugo.vm 00000001 test2.sugo.vm 00000002
  ```  
#### 3.1.3  开启服务
######  1. Postgres  
######  2. Redis  
######  3. Zookeeper  
######  4. 启动HDFS流程会多一些，需注意 
  a. 启动所有JournalNode  
  b. 在NameNode1节点上执行zkfc格式化：  
  ```
  su - hdfs -c "hdfs zkfc -formatZK -nonInteractive"
  ```
  c. 启动所有zkfc  
  d. 在NameNode1执行格式化操作  
  ```
  su - hdfs -c "hdfs namenode -format"
  ```
  e.  在NN2节点执行格式化后的数据同步  
  ```
  su - hdfs -c "hdfs namenode -bootstrapStandby"
  ```  
  f. 启动NameNode2，启动所有DataNode  
  g. 创建其它服务所需hdfs目录，在NameNode1或NameNode2上执行如下命令：
  ```
  su - hdfs
hdfs dfs -mkdir -p /remote-app-log/logs
hdfs dfs -chown -R yarn:hadoop  /remote-app-log
hdfs dfs -chmod 777 /remote-app-log/logs

hdfs dfs -mkdir -p /mr_history/tmp
hdfs dfs -chmod 777 /mr_history/tmp
hdfs dfs -mkdir -p /mr_history/done
hdfs dfs -chmod 777 /mr_history/done
hdfs dfs -mkdir -p /tmp/hadoop-yarn/staging
hdfs dfs -chmod 777 /tmp/hadoop-yarn/staging

hdfs dfs -mkdir -p /druid/hadoop-tmp
hdfs dfs -mkdir -p /druid/indexing-logs
hdfs dfs -mkdir -p /druid/segments
hdfs dfs -chown -R druid:druid /druid
hdfs dfs -mkdir -p /user/druid
hdfs dfs -chown -R druid:druid /user/druid

hdfs dfs -mkdir -p /tmp/spark-events
hdfs dfs -chmod 777 /tmp/spark-events
hdfs dfs -mkdir -p /user/spark
hdfs dfs -chmod 777 /user/spark
hdfs dfs -chown -R spark:spark /user/spark

hdfs dfs -mkdir -p /tmp/hive
hdfs dfs -chmod 777 /tmp/hive
hdfs dfs -chown -R hive:hadoop /tmp/hive
hdfs dfs -mkdir -p /user/hive
hdfs dfs -chmod 777 /user/hive
hdfs dfs -chown -R hive:hadoop /user/hive

```
######  5. YARN
######  6. MapReduce
######  7. Kafka
######  8. Gateway
######  9. Druid启动
Druid和Astro等服务依赖Postgres数据库，需在Postgres安装节点分别创建druid数据库和sugo_astro数据库，注意postgres的端口号及用户(pio库和hive库是为可能安装pio或hive准备的)
```
cd /opt/apps/postgres_sugo
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE pio WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE hive WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
```
启动Druid
######  10. Astro
######  11. Spark(可选,需要上传安装包)
######  12. Hive(可选,需要上传安装包)
修改配置项javax.jdo.option.ConnectionURL的值为：jdbc:postgresql://ds1.sugo.io:15432/hive?createDatabaseIfNotExist=true
重启hive的所有服务
######  13. Pio(可选,需要上传安装包)
安装python2.7运行环境:
下载python2.7环境安装包anaconda2.7，解压缩到目录/usr/local/下
    
    
### 3.2 Web安装

#### 3.2.1  Postgresql安装  ###
添加服务  
勾选想要安装的组件，点击下一步  
分配该服务安装在哪些节点上  
完成配置文件(安装PostgreSQL需要修改端口号，其它组件一般不需要修改)  
postgres.password: 123456 123456  
port: 15432  
检查配置信息、部署  
安装启动和测试，等待安装完成  
安装完成

#### 3.2.2  Redis安装 ###

#### 3.2.3  Zookeeper安装 ###
注：生产环境中至少部署三个节点

#### 3.2.4  HDFS安装 ###
###### a 环境要求：  
保证两个目录地址NameNode.dfs.namenode.name.dir不存在  
两个NameNode的hdfs用户能互相免密码登录

###### b 可修改参数：  
```
dfs.namenode.name.dir  
dfs.namenode.data.dir  
hadoop.log.dir  
dfs.journalnode.edits.dir  
hadoop.tmp.dir  
```

###### c 安装：  
此处的HDFS为HA模式，有两个NameNode，假设NN1为Active Namenode，NN2为Standby Namenode。

正常情况下会报错ZKFailoverController(zkfc)启动失败，不报错表示已经安装过HDFS，跳过失败，点击下一步，按照以下顺序操作：  

1) 在NN1节点执行：  
```
su - hdfs -c "hdfs zkfc -formatZK -nonInteractive"
```
2) 启动所有zkfc  
重新启动所有ZKFailoverController
3) 在NN1节点执行格式化：  
```
su - hdfs -c "hdfs namenode -format"  
```
4) 启动NN1
5) 在NN2节点执行格式化后的数据同步：  
```
su - hdfs -c "hdfs namenode -bootstrapStandby"  
```
6) 启动NN2
7) 重启所有DataNode

#### 3.2.5  Yarn安装
可修改参数：  
YARN Log Dir Prefix  
yarn.nodemanager.log-dirs  
yarn.nodemanager.local-dirs  

hdfs目录创建：  
此处假设yarn.nodemanager.remote-app-log-dir为默认hdfs目录/remote-app-log/logs:  
```
su - hdfs  
hdfs dfs -mkdir -p /remote-app-log/logs
hdfs dfs -chown -R yarn:hadoop  /remote-app-log
hdfs dfs -chmod 777 /remote-app-log/logs
```

#### 3.2.6  MapReduce安装
可修改参数：  
MapRduce Log Dir Prefix  
yarn.app.mapreduce.am.staging-dir  

hdfs目录创建： 

```
su - hdfs
hdfs dfs -mkdir -p /mr_history/tmp  
hdfs dfs -chmod 777 /mr_history/tmp  
hdfs dfs -mkdir -p /mr_history/done  
hdfs dfs -chmod 777 /mr_history/done  
hdfs dfs -mkdir -p /tmp/hadoop-yarn/staging  
hdfs dfs -chmod 777 /tmp/hadoop-yarn/staging  
```

#### 3.2.7  Druid安装
环境要求：  
Postgresql(可通过界面安装)  
创建druid库(UTF8，Postgres)（3.8.1和3.8.2选一种方法即可，建议3.8.2 ）  

###### a 界面建库：  
下载、安装Postgresql界面管理工具Navicat for PostgreSQL，连接数据库，创建druid库

如果连接时显示密码错误，则进入postgres用户，进行参数设置  
```
/opt/apps/postgres_sugo/bin/psql -d postgres -U postgres -p 15432 -c "ALTER USER postgres PASSWORD '123456';"
```  

###### b CLI命令建库：

```
cd /opt/apps
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
```

建议修改参数：  

```druid.metadata.storage.connector
druid.license.signature: 
druid.metadata.storage.connector.connectURI: jdbc:postgresql://test01.sugo.vm:15432/druid
druid.metadata.storage.connector.password: 123456 123456
```

自定义参数：  

```
supervisor.kafka.zkHost:
```
如果已有在用的Zookeeper，则此配置需要加上，host:端口号有在用的的  
192.168.1.122:2181,192.168.1.126:2181,192.168.1.240:2181(例)  

hdfs目录创建：  
```
su - hdfs
hdfs dfs -mkdir -p /druid/hadoop-tmp
hdfs dfs -mkdir -p /druid/indexing-logs
hdfs dfs -mkdir -p /druid/segments
hdfs dfs -chown -R druid:druid /druid
hdfs dfs -mkdir -p /user/druid
hdfs dfs -chown -R druid:druid /user/druid
```

#### 3.2.8  Kafka安装
可修改参数：
log.dirs

#### 3.2.9  Astro安装
环境要求：  
Postgresql(可通过界面安装)，并创建sugo_astro库(UTF8，Postgresl)：  
Redis(可通过界面安装)  
```
cd /opt/apps
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
```


建议修改参数：
```
postgres.host: test01.sugo.vm
dataConfig.hostAndPorts: test01.sugo.vm:6379
db.host: test01.sugo.vm
db.port: 15432
db.password: 123456 123456
redis.host: test01.sugo.vm
site.sdk_ws_url: ws://test01.sugo.vm:8887
site.websdk_api_host: test01.sugo.vm
site.websdk_decide_host: test01.sugo.vm:8000
site.collectGateway: http://test01.sugo.vm
```

#### 3.2.10 安装Openresty(可选，需要上传安装包)
环境要求：  
redis(可通过界面安装)  
注意：如果前面httpd服务的端口号没有修改，则会与nginx的端口产生冲突  
可修改参数：
```
log.bakcup.dir:  
nginx.working_directory:  
redis_host:  
```
自定义参数（此参数在使用非sugo提供的kafka时添加，使用sugo安装kafka时不需要添加）：  
kafka.brokers: 192.168.1.122:59092,192.168.1.126:59092,192.168.1.240:59092（例）

####  3.2.11 Spark(可选,需要上传安装包)
hdfs目录创建：
```
su hdfs
hdfs dfs -mkdir -p /tmp/spark-events
hdfs dfs -chmod 777 /tmp/spark-events
hdfs dfs -mkdir -p /user/spark
hdfs dfs -chmod 777 /user/spark
hdfs dfs -chown -R spark:spark /user/spark
```
####  3.2.12 Hive(可选,需要上传安装包)
修改配置项javax.jdo.option.ConnectionURL的值为：jdbc:postgresql://test1.sugo.vm:15432/hive?createDatabaseIfNotExist=true
重启hive的所有服务

hdfs目录创建：
```
su hdfs
hdfs dfs -mkdir -p /tmp/hive
hdfs dfs -chmod 777 /tmp/hive
hdfs dfs -chown -R hive:hadoop /tmp/hive
hdfs dfs -mkdir -p /user/hive
hdfs dfs -chmod 777 /user/hive
hdfs dfs -chown -R hive:hadoop /user/hive
```

####  3.2.13 Pio(可选,需要上传安装包)
安装python2.7运行环境:
下载python2.7环境安装包，解压缩到目录/usr/local/下


## 4 验证安装是否成功
至此，服务安装完成，查看Web界面、导入数据验证安装成功，具体可查看视频  
查看的服务：  
HDFS（包括activeNamenode，standbyNamenode）  
DruidIO  
Astro（admin:admin123456,创建项目、导入数据、采集数据、查询数据）