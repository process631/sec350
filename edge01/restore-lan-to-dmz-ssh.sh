#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

configure

set firewall ipv4 name LAN-to-DMZ default-action 'drop'
set firewall ipv4 name LAN-to-DMZ default-log
set firewall ipv4 name LAN-to-DMZ rule 1 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 1 state 'established'
set firewall ipv4 name LAN-to-DMZ rule 1 state 'related'
set firewall ipv4 name LAN-to-DMZ rule 30 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 30 protocol 'tcp'
set firewall ipv4 name LAN-to-DMZ rule 30 source address '172.16.150.10'
set firewall ipv4 name LAN-to-DMZ rule 30 destination address '172.16.50.3'
set firewall ipv4 name LAN-to-DMZ rule 30 destination port '22'
set firewall zone DMZ from LAN firewall name 'LAN-to-DMZ'

commit
save
exit
