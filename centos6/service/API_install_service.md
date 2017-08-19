��Ambari-servers��װ��ɺ���Ҫ��Ambari�ϰ�װ��ط��񣬴˲���ͨ��http�������Ambari API��ʵ�ַ���İ�װ��

׼����  
�ڰ�װ����service��֮ǰ����Ҫ���ü�Ⱥ�����װ�滮���˲����ڽű��Զ���������ϲ����Ѿ�׼���ã����滮�õ������������Ϣת����ʽ�����ո�ʽ���Ŀ¼�µ�host-service.json�ļ�  
�޸Ľű�install.py�ڵ�base_url  
���޸ĵĽű����ļ���  
```
host-service.json  
install.py

```
������װ�ű�
```
python install.py
```
  
  ����װ��ɺ��޸���ط���������ļ�������NameNode1��NameNode2�µ�hdfs�û����������¼����֤HDFS�ĸ߿��ã�Ȼ����һ��˳����������  
  
���޸����ã�  
|Services| Files|Parameters|Value(example)|Alter|Attention
|-------|----------|----------|----------|----------|----------
|Postgres   |postgres-env|postgres.password | 123456| ��	|
|           |               | port             | 15432 |      |��
|Druid      |   common.runtime|druid.license.signature|��ƽ�ṩ| ��	��	��
|           |               |druid.metadata.storage.connector.connectURI| jdbc:postgresql://dev220.sugo.net:15432/druid|��
|||druid.metadata.storage.connector.password|123456|��||��	
|||druid.zk.service.host|{{zk_address}}||��
|OpenResty|openresty-site|redis_host|dev220.sugo.net|��|
|Astro|astro-site|dataConfig.hostAndPorts|dev220.sugo.net:6379|��|
|||db.host|dev220.sugo.net|��||
|||db.password|123456|��||
|||db.port|15432|��|
|||redis.host|dev220.sugo.net|��|
|||site.collectGateway|http://dev220.sugo.net|��|
|||site.sdk_ws_url| ws://dev220.sugo.net:8887|��|
|||site.websdk_api_host|dev220.sugo.net|��|
|||site.websdk_decide_host|dev220.sugo.net:8080|��|
|AMS|ams-grafana-env|Grafana Admin Password|admin|��|


  

  ����NameNode1��NameNode2�µ�hdfs�û����������¼���������ýű������ϲ�����ע��passwdΪroot�û����룩��  
  ```
  ./password-less-ssh-hdfs.sh $NN1 $passwd(NN1) $NN2 $passwd(NN2)
  ```  
  
######  1. Postgres  
######  2. Redis  
######  3. Zookeeper  
######  4. ����HDFS���̻��һЩ����ע�� 
  a. ��������JournalNode  
  b. ��NameNode1�ڵ���ִ��zkfc��ʽ����  
  ```
  su - hdfs -c "hdfs zkfc -formatZK -nonInteractive"
  ```
  c. ��������zkfc  
  d. ��NameNode1ִ�и�ʽ������  
  ```
  su - hdfs -c "hdfs namenode -format"
  ```
  e.  ��NN2�ڵ�ִ�и�ʽ���������ͬ��  
  ```
  su - hdfs -c "hdfs namenode -bootstrapStandby"
  ```  
  f. ����NameNode2����������DataNode  
  g. ����������������hdfsĿ¼����NameNode1��NameNode2��ִ���������
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
######  7. Druid����
Druid��Astro����Postgres���ݿ⣬����Postgres��װ�ڵ�ֱ𴴽�druid���ݿ��sugo_astro���ݿ�
```
cd /opt/apps
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "select datname from pg_database"
```
����Druid
######  8.Astro
######  9.Kafka
######  10.OpenResty

  
  
### ����
���ˣ�����װ���  
�鿴�������Web���桢����������֤��װ�Ƿ�ɹ�  
�鿴�ķ���
HDFS������activeNamenode��standbyNamenode��  
DruidIO  
Astro��admin:admin123456,������Ŀ���������ݡ��ɼ����ݣ�
