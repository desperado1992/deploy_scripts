# ambari-agent脚本使用说明 #

## 1. 准备 ##
### hosts文件
hosts文件用于写入需要添加的agent的主机名, root用户的密码，该主机的IP地址
按行写入，每行代表一个主机(ambari-agent)，各项目之间以空格“ ”分割
例：
```
test3.sugo.vm 123456789 192.168.0.110
```

## 2. 脚本使用 ##
### pre_add_agent.sh
此脚本用于安装agent之前的主机准备，包括安装jdk、配置ambari-server到该agent的ssh免密码登录、系统优化等，且jdk、ssh免密码可选择性安装
具体使用可通过如下命令进行查看
```
./pre_agent.sh -help
```

### install_agent.py
此脚本用于安装ambari-agent，会在指定文件中列出的主机上安装注册ambari-agent，运行此脚本需输入参数：集群名称 ambari-server的IP地址 指定文件
例：
```
python install_agent.py testCluster 192.168.0.110 hosts
```
### regist_agent.py
此脚本用于注册ambari-agent，安装完ambari-agent之后，需要将agent注册到集群中，此脚本使用参数与install_agent.py参数相同
例：
```
python regist_agent.py testCluster 192.168.0.110 hosts
```
注意：此脚本可能执行失败，是因为安装ambari-agent需要时间，一般在安装脚本执行完以后15s左右执行此脚本，如果此脚本执行失败，重复执行即可
