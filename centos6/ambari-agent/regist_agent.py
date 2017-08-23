#!/usr/bin/python
#coding=utf-8

import json, os, sys, time
import urllib2

# need to be altered
cluster_name = sys.argv[1]
ambari_server_ip = sys.argv[2]
agent_file = sys.argv[3]

a = open(agent_file, "r+")
hosts = []

for line in a:
    host = line.split(" ")[1].strip('\n')
    hosts.append(host)





# register ambari-agent
for host in hosts:
    url1 = "http://" + ambari_server_ip + ":8080/api/v1/clusters/" + cluster_name + "/hosts/" + host
    print url1
    request_register = urllib2.Request(url1)
    request_register.add_header('Authorization', 'Basic YWRtaW46YWRtaW4=')
    request_register.add_header('Content-Type', 'application/json')
    request_register.add_header('X-Requested-By', 'ambari')
    print request_register
    response2 = urllib2.urlopen(request_register, "", 60)
    print response2.read()

