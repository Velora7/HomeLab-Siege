#!/bin/bash
sudo iptables -I INPUT 1 -s 192.168.122.197 -j DROP
echo "Attacker blocked."
