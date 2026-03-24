#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

configure
set nat destination rule 20 description 'WAN SSH to jump'
set nat destination rule 20 inbound-interface name 'eth0'
set nat destination rule 20 protocol 'tcp'
set nat destination rule 20 destination port '22'
set nat destination rule 20 translation address '172.16.50.4'
set nat destination rule 20 translation port '22'
commit
save
exit
