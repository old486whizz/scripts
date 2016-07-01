#! /bin/sh

# $1 - device to accept packets on
# $2 - device to forward packets through

/etc/init.d/iptables start
iptables --flush FORWARD
iptables --table nat --flush
# iptables --delete-chain
iptables --table nat --delete-chain
iptables --table nat --append POSTROUTING --out-interface $2 -j MASQUERADE
iptables --append FORWARD --in-interface $1 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward

