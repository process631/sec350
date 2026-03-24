#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

configure
set firewall ipv4 name LAN-to-DMZ rule 40 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 40 protocol 'tcp'
set firewall ipv4 name LAN-to-DMZ rule 40 destination address '172.16.200.10'
set firewall ipv4 name LAN-to-DMZ rule 40 destination port '1514-1515'
set firewall ipv4 name LAN-to-DMZ rule 40 description 'Allow LAN agents to Wazuh manager'
commit
save
exit
