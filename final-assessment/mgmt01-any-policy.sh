#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

configure

set firewall ipv4 name MGMT01-ANY rule 10 description "Allow any from mgmt01"
set firewall ipv4 name MGMT01-ANY rule 10 action accept
set firewall ipv4 name MGMT01-ANY rule 10 source address 172.16.200.10

set firewall ipv4 name MGMT01-RETURN rule 10 description "Allow established"
set firewall ipv4 name MGMT01-RETURN rule 10 action accept
set firewall ipv4 name MGMT01-RETURN rule 10 state established enable

set firewall ipv4 name MGMT01-RETURN rule 20 description "Allow related"
set firewall ipv4 name MGMT01-RETURN rule 20 action accept
set firewall ipv4 name MGMT01-RETURN rule 20 state related enable

set firewall zone LAN from MGMT firewall name MGMT01-ANY
set firewall zone MGMT from LAN firewall name MGMT01-RETURN

commit
save
exit
