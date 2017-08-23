#!/usr/bin/python
#coding=utf-8
import json, sys

input_file = sys.argv[1]
a = open(input_file)
b = json.loads(a.read())

for i in range(len(b["items"])):
	component = b["items"][i]["ServiceComponentInfo"]["component_name"]
	if component == "SUGO_JOURNALNODE":
	    c = b["items"][i]
	    #print c
	    for j in range(len(c["host_components"])):
		    d = c["host_components"][j]["HostRoles"]["state"]
		    print d
