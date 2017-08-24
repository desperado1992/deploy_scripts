#!/bin/bash

#判断astro是否已经安装完成
  astro_dir="/opt/apps/astro_sugo"
  while [ ! -d "$astro_dir" ]
  do
    astro_dir="/opt/apps/astro_sugo"
    if [ ! -d "$astro_dir" ];then
      echo "waiting for astro to be installed~~~"
      sleep 2
      continue
    else
	  echo "astro has been installed!~~~"
      break
    fi
  done
