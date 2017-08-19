#!/bin/bash

/usr/sbin/ntpdate -u 202.108.6.95
service ntpd restart


### set the limits
res=`grep '*          hard    nproc     unlimited' /etc/security/limits.d/90-nproc.conf`
if [ "$res" = "" ]
   then 
      echo "*          hard    nproc     unlimited" >> /etc/security/limits.d/90-nproc.conf
fi

res=`grep '*          soft    nproc     unlimited' /etc/security/limits.d/90-nproc.conf`
if [ "$res" = "" ]
   then 
      echo "*          soft    nproc     unlimited" >> /etc/security/limits.d/90-nproc.conf
fi


res=`grep '* soft nofile 65535' /etc/security/limits.conf `
if [ "$res" = "" ]
   then 
      echo "* soft nofile 65535"  >>  /etc/security/limits.conf 
fi 

res=`grep '* hard nofile 65535' /etc/security/limits.conf `
if [ "$res" = "" ]
   then 
      echo "* hard nofile 65535"  >>  /etc/security/limits.conf 
fi 


##�ر�THP
echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag

res=`grep "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" /etc/rc.local`
if [ "$res" = "" ]
   then
     echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled" >> /etc/rc.local
fi

res=`grep "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" /etc/rc.local`
if [ "$res" = "" ]
   then
     echo "echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag" >> /etc/rc.local
fi

#�رշ���ǽ
service iptables stop 
chkconfig iptables off 

#�ر�selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#����޶�ʹ�������ڴ�
res=`grep 'vm.swappiness' /etc/sysctl.conf`
if [ "$res" = "" ]
   then
     echo "vm.swappiness=0" >> /etc/sysctl.conf
fi
swapoff -a

res=`grep 'vm.max_map_count' /etc/sysctl.conf`
if [ "$res" = "" ]
   then
     echo "vm.max_map_count=6553600" >> /etc/sysctl.conf
fi

sysctl -p

yum upgrade openssl -y 

