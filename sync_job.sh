#! /bin/bash

# -- insert stuff here
# -- version info etc

exec 1>>/unison.err
exec 2>&1

if [[ `find /etc -mmin -10 |wc -l` != 0 ]]; then
  tar -Pzcvf /root/`hostname`.etc.tgz /etc/fstab /etc/crypttab /etc/sudoers /etc/X11/xorg.c* /etc/sysctl.conf /etc/alternatives /etc/udev/rules.d/70-persistent-cd.rules
fi

unison -batch -ui text ssh://192.168.1.8//server/sync/home/root /root
unison -batch -ui text ssh://192.168.1.8//server/sync/home/Tr0n /home/Tr0n

