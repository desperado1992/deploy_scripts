在Ambari-servers安装完成后，需要在Ambari上安装相关服务，此部分通过http服务调用Ambari API来实现服务的安装。

准备：  
在安装服务（service）之前，需要做好集群组件安装规划，此部分在脚本自动化部署的上部分已经准备好，将规划好的组件及主机信息转换格式，按照格式完成目录下的host-service.json文件  
修改脚本install.py内的base_url  
需修改的脚本或文件：  
```
host-service.json  
install.py

```
启动安装脚本
```
python install.py
```
  
  待安装完成后，修改相关服务的配置文件，配置NameNode1和NameNode2下的hdfs用户的免密码登录，保证HDFS的高可用，然后按照一定顺序启动服务  
  
需修改配置：  
|Services| Files|Parameters|Value(example)|Alter|Attention
|-------|----------|----------|----------|----------|----------
|Postgres   |postgres-env|postgres.password | 123456| √	|
|           |               | port             | 15432 |      |√
|Druid      |   common.runtime|druid.license.signature|建平提供| √	　	　
|           |               |druid.metadata.storage.connector.connectURI| jdbc:postgresql://dev220.sugo.net:15432/druid|√
|||druid.metadata.storage.connector.password|123456|√||　	
|||druid.zk.service.host|{{zk_address}}||√
|OpenResty|openresty-site|redis_host|dev220.sugo.net|√|
|Astro|astro-site|dataConfig.hostAndPorts|dev220.sugo.net:6379|√|
|||db.host|dev220.sugo.net|√||
|||db.password|123456|√||
|||db.port|15432|√|
|||redis.host|dev220.sugo.net|√|
|||site.collectGateway|http://dev220.sugo.net|√|
|||site.sdk_ws_url| ws://dev220.sugo.net:8887|√|
|||site.websdk_api_host|dev220.sugo.net|√|
|||site.websdk_decide_host|dev220.sugo.net:8080|√|
|AMS|ams-grafana-env|Grafana Admin Password|admin|√|


  

  配置NameNode1和NameNode2下的hdfs用户的免密码登录，启动配置脚本并带上参数（注：passwd为root用户密码）：  
  ```
  ./password-less-ssh-hdfs.sh $NN1 $passwd(NN1) $NN2 $passwd(NN2)
  ```  
  
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

```
######  5. YARN
######  6. MapReduce
######  7. Druid启动
Druid和Astro依赖Postgres数据库，需在Postgres安装节点分别创建druid数据库和sugo_astro数据库
```
cd /opt/apps
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
```
启动Druid
######  8.Astro
######  9.Kafka
######  10.OpenResty

  
  
### 检验
至此，服务安装完成  
查看各服务的Web界面、导入数据验证安装是否成功  
查看的服务：
HDFS（包括activeNamenode，standbyNamenode）  
DruidIO  
Astro（admin:admin123456,创建项目、导入数据、采集数据）
