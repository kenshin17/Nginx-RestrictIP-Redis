#!/usr/bin/python
import redis
ip = open("ip_whitelist.txt")
r = redis.StrictRedis(host='localhost', port=6379, db=15)

for i in ip:
    r.sadd("IP_WHITELIST",i.strip())

print ("Done")

