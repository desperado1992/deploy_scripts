#!/bin/bash
#如果客户已创建/data目录且位于较大磁盘分区下，则通过符号链接减少磁盘占用

#日志、元数据存储目录--$1

cd ../../..
data_dir=`echo $(dirname $(pwd))`
echo $data_dir
conf_file=$1

if [ $data_dir == "/" ]
then
	mkdir /data1 /data2
	
	echo "数据将直接保存在/data1 和 /data2 目录中，请确保此目录有足够的空间"
	
	cat deploy_scripts/centos6/$conf_file |while read line;
	do
	hn=`echo $line|awk '{print $1}'`
	pw=`echo $line|awk '{print $2}'`
	
	/usr/bin/expect <<-EOF
	set timeout 100000
	spawn ssh $hn
		expect {
		"*yes/no*" { send "yes\n"
		expect "*assword:" { send "$pw\n" } }
		"*assword:" { send "$pw\n" } 
			expect "*]#*" 
		{ send "mkdir /data1 /data2\n" }
			expect "*]#*"
		}
			expect "*#*" 
		send "mkdir /data1 /data2\n"
			expect "*]#*"
	EOF
	done

else
	mkdir -p $data_dir/data1 $data_dir/data2 
	ln -s $data_dir/data1 /
	ln -s $data_dir/data2 /

	cat deploy_scripts/centos6/$conf_file |while read line;
	do
	hn=`echo $line|awk '{print $1}'`
	pw=`echo $line|awk '{print $2}'`
	
	/usr/bin/expect <<-EOF
	set timeout 100000
	spawn ssh $hn
		expect {
		"*yes/no*" { send "yes\n"
		expect "*assword:" { send "$pw\n" } }
		"*assword:" { send "$pw\n" } 
		"*]#*" { send "mkdir -p $data_dir/data1 $data_dir/data2\n" }
			expect "*]#*" 
		send "ln -s $data_dir/data1 /data1\n" 
			expect "*]#*" 
		send "ln -s $data_dir/data2 /data2\n"
			expect "*]#*"
		}
			expect "*]#*" 
		send "mkdir -p $data_dir/data1 $data_dir/data2\n"
			expect "*]#*" 
		send "ln -s $data_dir/data1 /data1\n"
			expect "*]#*" 
		send "ln -s $data_dir/data2 /data2\n"
			expect "*]#*"
	EOF
	done
fi
