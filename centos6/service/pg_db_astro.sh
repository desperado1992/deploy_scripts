#!/bin/bash

#创建druid、sugo_astro/pio库
postgres_path="/opt/apps/postgres_sugo"
if [ -d "$postgres_path" ];
then
postgres_pid=`head -1 /data1/postgres/data/postmaster.pid`
    if [ "$postgres_pid" = "" ];
        then
        su - postgres -c "/opt/apps/postgres_sugo/bin/pg_ctl -D /data1/postgres/data -l /data1/postgres/log/postgres.log start"
        sleep 3
    fi

cd /opt/apps/postgres_sugo
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE druid WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE sugo_astro WITH OWNER = postgres ENCODING = UTF8;"
bin/psql -p 15432 -U postgres -d postgres -c "CREATE DATABASE pio WITH OWNER = postgres ENCODING = UTF8;"
cd -
fi

#判断astro是否已经安装完成
  printf "waiting for astro to be installed"
  astro_dir="/opt/apps/astro_sugo"
  while [ ! -d "$astro_dir" ]
  do
    astro_dir="/opt/apps/astro_sugo"
    if [ ! -d "$astro_dir" ];then
      printf "."
      sleep 2
      continue
    else
      echo ""
      echo "astro has been installed!~~~"
      break
    fi
  done
