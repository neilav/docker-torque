#!/bin/bash
FIXEDHOSTNAME='master'
# Get current IP
IP=$(ip -4 addr show eth0| grep -Po 'inet \K[\d.]+')
echo "$IP $FIXEDHOSTNAME" >> /etc/hosts
