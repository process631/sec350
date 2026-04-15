#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# SEC-350 Final Assessment - edge01 bootstrap
# Safe to re-run; it replaces only the objects it manages.

configure

# ---- Identity ----
set system host-name 'edge01'

# ---- Interfaces ----
set interfaces ethernet eth0 description 'WAN'
set interfaces ethernet eth0 address '10.0.17.115/24'
set interfaces ethernet eth1 description 'DMZ'
set interfaces ethernet eth1 address '172.16.50.2/29'
set interfaces ethernet eth2 description 'LAN'
set interfaces ethernet eth2 address '172.16.150.2/24'

# ---- Routes ----
set protocols static route 0.0.0.0/0 next-hop '10.0.17.2'
set protocols static route 172.16.200.0/28 next-hop '172.16.150.3'

# ---- Routing protocol (assessment requirement) ----
set protocols rip interface 'eth1'
set protocols rip network '172.16.50.0/29'

# ---- NAT (outbound) ----
delete nat source rule 100
set nat source rule 100 description 'DMZ outbound NAT'
set nat source rule 100 outbound-interface name 'eth0'
set nat source rule 100 source address '172.16.50.0/29'
set nat source rule 100 translation address 'masquerade'

delete nat source rule 110
set nat source rule 110 description 'LAN outbound NAT'
set nat source rule 110 outbound-interface name 'eth0'
set nat source rule 110 source address '172.16.150.0/24'
set nat source rule 110 translation address 'masquerade'

# ---- NAT (inbound DNAT for traveler access) ----
delete nat destination rule 10
set nat destination rule 10 description 'WAN 80 -> nginx 80'
set nat destination rule 10 inbound-interface name 'eth0'
set nat destination rule 10 protocol 'tcp'
set nat destination rule 10 destination port '80'
set nat destination rule 10 translation address '172.16.50.3'
set nat destination rule 10 translation port '80'

delete nat destination rule 11
set nat destination rule 11 description 'WAN 443 -> nginx 443'
set nat destination rule 11 inbound-interface name 'eth0'
set nat destination rule 11 protocol 'tcp'
set nat destination rule 11 destination port '443'
set nat destination rule 11 translation address '172.16.50.3'
set nat destination rule 11 translation port '443'

delete nat destination rule 20
set nat destination rule 20 description 'WAN 22 -> jump 22'
set nat destination rule 20 inbound-interface name 'eth0'
set nat destination rule 20 protocol 'tcp'
set nat destination rule 20 destination port '22'
set nat destination rule 20 translation address '172.16.50.4'
set nat destination rule 20 translation port '22'

# ---- DNS forwarding (assessment requirement) ----
set service dns forwarding allow-from '172.16.50.0/29'
set service dns forwarding allow-from '172.16.150.0/24'
set service dns forwarding allow-from '172.16.200.0/28'
set service dns forwarding listen-address '172.16.50.2'
set service dns forwarding listen-address '172.16.150.2'
set service dns forwarding system

# ---- Local named power user (assessment requirement) ----
# Replace <HASHED_PASSWORD> with a real encrypted password string before running.
set system login user 'poweredge' full-name 'Edge01 Power User'
set system login user 'poweredge' authentication encrypted-password '<HASHED_PASSWORD>'

# ---- Firewall policy sets ----
delete firewall ipv4 name WAN-to-DMZ
set firewall ipv4 name WAN-to-DMZ description 'WAN to DMZ policy'
set firewall ipv4 name WAN-to-DMZ default-action 'drop'
set firewall ipv4 name WAN-to-DMZ default-log
set firewall ipv4 name WAN-to-DMZ rule 1 action 'accept'
set firewall ipv4 name WAN-to-DMZ rule 1 state 'established'
set firewall ipv4 name WAN-to-DMZ rule 1 state 'related'
set firewall ipv4 name WAN-to-DMZ rule 20 action 'accept'
set firewall ipv4 name WAN-to-DMZ rule 20 description 'Allow SSH to jump (DNAT)'
set firewall ipv4 name WAN-to-DMZ rule 20 protocol 'tcp'
set firewall ipv4 name WAN-to-DMZ rule 20 destination address '172.16.50.4'
set firewall ipv4 name WAN-to-DMZ rule 20 destination port '22'
set firewall ipv4 name WAN-to-DMZ rule 30 action 'accept'
set firewall ipv4 name WAN-to-DMZ rule 30 description 'Allow HTTP to nginx (DNAT)'
set firewall ipv4 name WAN-to-DMZ rule 30 protocol 'tcp'
set firewall ipv4 name WAN-to-DMZ rule 30 destination address '172.16.50.3'
set firewall ipv4 name WAN-to-DMZ rule 30 destination port '80'
set firewall ipv4 name WAN-to-DMZ rule 40 action 'accept'
set firewall ipv4 name WAN-to-DMZ rule 40 description 'Allow HTTPS to nginx (DNAT)'
set firewall ipv4 name WAN-to-DMZ rule 40 protocol 'tcp'
set firewall ipv4 name WAN-to-DMZ rule 40 destination address '172.16.50.3'
set firewall ipv4 name WAN-to-DMZ rule 40 destination port '443'

delete firewall ipv4 name WAN-to-LAN
set firewall ipv4 name WAN-to-LAN description 'WAN to LAN policy'
set firewall ipv4 name WAN-to-LAN default-action 'drop'
set firewall ipv4 name WAN-to-LAN default-log
set firewall ipv4 name WAN-to-LAN rule 1 action 'accept'
set firewall ipv4 name WAN-to-LAN rule 1 state 'established'
set firewall ipv4 name WAN-to-LAN rule 1 state 'related'

delete firewall ipv4 name LAN-to-WAN
set firewall ipv4 name LAN-to-WAN description 'LAN to WAN policy'
set firewall ipv4 name LAN-to-WAN default-action 'drop'
set firewall ipv4 name LAN-to-WAN default-log
set firewall ipv4 name LAN-to-WAN rule 1 action 'accept'
set firewall ipv4 name LAN-to-WAN rule 1 state 'established'
set firewall ipv4 name LAN-to-WAN rule 1 state 'related'
set firewall ipv4 name LAN-to-WAN rule 20 action 'accept'
set firewall ipv4 name LAN-to-WAN rule 20 description 'Allow LAN outbound'

delete firewall ipv4 name DMZ-to-WAN
set firewall ipv4 name DMZ-to-WAN description 'DMZ to WAN policy'
set firewall ipv4 name DMZ-to-WAN default-action 'drop'
set firewall ipv4 name DMZ-to-WAN default-log
set firewall ipv4 name DMZ-to-WAN rule 1 action 'accept'
set firewall ipv4 name DMZ-to-WAN rule 1 state 'established'
set firewall ipv4 name DMZ-to-WAN rule 1 state 'related'

delete firewall ipv4 name LAN-to-DMZ
set firewall ipv4 name LAN-to-DMZ description 'LAN to DMZ policy'
set firewall ipv4 name LAN-to-DMZ default-action 'drop'
set firewall ipv4 name LAN-to-DMZ default-log
set firewall ipv4 name LAN-to-DMZ rule 1 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 1 state 'established'
set firewall ipv4 name LAN-to-DMZ rule 1 state 'related'
set firewall ipv4 name LAN-to-DMZ rule 20 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 20 description 'Allow mgmt01 SSH to DMZ hosts'
set firewall ipv4 name LAN-to-DMZ rule 20 source address '172.16.150.10'
set firewall ipv4 name LAN-to-DMZ rule 20 protocol 'tcp'
set firewall ipv4 name LAN-to-DMZ rule 20 destination port '22'
set firewall ipv4 name LAN-to-DMZ rule 30 action 'accept'
set firewall ipv4 name LAN-to-DMZ rule 30 description 'Allow LAN to nginx HTTPS'
set firewall ipv4 name LAN-to-DMZ rule 30 destination address '172.16.50.3'
set firewall ipv4 name LAN-to-DMZ rule 30 protocol 'tcp'
set firewall ipv4 name LAN-to-DMZ rule 30 destination port '443'

delete firewall ipv4 name DMZ-to-LAN
set firewall ipv4 name DMZ-to-LAN description 'DMZ to LAN policy'
set firewall ipv4 name DMZ-to-LAN default-action 'drop'
set firewall ipv4 name DMZ-to-LAN default-log
set firewall ipv4 name DMZ-to-LAN rule 1 action 'accept'
set firewall ipv4 name DMZ-to-LAN rule 1 state 'established'
set firewall ipv4 name DMZ-to-LAN rule 1 state 'related'
set firewall ipv4 name DMZ-to-LAN rule 20 action 'accept'
set firewall ipv4 name DMZ-to-LAN rule 20 description 'Allow Wazuh agents to manager'
set firewall ipv4 name DMZ-to-LAN rule 20 protocol 'tcp'
set firewall ipv4 name DMZ-to-LAN rule 20 destination address '172.16.200.10'
set firewall ipv4 name DMZ-to-LAN rule 20 destination port '1514-1515'

# ---- WAN local policy (explicitly block ICMP to edge01 from WAN) ----
delete firewall ipv4 name WAN-LOCAL
set firewall ipv4 name WAN-LOCAL description 'Traffic destined to edge01 from WAN'
set firewall ipv4 name WAN-LOCAL default-action 'drop'
set firewall ipv4 name WAN-LOCAL default-log
set firewall ipv4 name WAN-LOCAL rule 1 action 'accept'
set firewall ipv4 name WAN-LOCAL rule 1 state 'established'
set firewall ipv4 name WAN-LOCAL rule 1 state 'related'

# Optional: allow SSH to edge01 only from LAN admin segment
set firewall ipv4 name WAN-LOCAL rule 10 action 'accept'
set firewall ipv4 name WAN-LOCAL rule 10 description 'Allow SSH to edge01 only from LAN'
set firewall ipv4 name WAN-LOCAL rule 10 protocol 'tcp'
set firewall ipv4 name WAN-LOCAL rule 10 source address '172.16.150.0/24'
set firewall ipv4 name WAN-LOCAL rule 10 destination port '22'

# ---- Zone bindings ----
set firewall zone WAN description 'External zone'
set firewall zone WAN member interface 'eth0'
set firewall zone WAN from LAN firewall name 'LAN-to-WAN'
set firewall zone WAN from DMZ firewall name 'DMZ-to-WAN'

set firewall zone DMZ description 'DMZ zone'
set firewall zone DMZ member interface 'eth1'
set firewall zone DMZ from WAN firewall name 'WAN-to-DMZ'
set firewall zone DMZ from LAN firewall name 'LAN-to-DMZ'

set firewall zone LAN description 'Internal LAN zone'
set firewall zone LAN member interface 'eth2'
set firewall zone LAN from WAN firewall name 'WAN-to-LAN'
set firewall zone LAN from DMZ firewall name 'DMZ-to-LAN'

# Bind local policy to WAN interface
set interfaces ethernet eth0 firewall local name 'WAN-LOCAL'

commit
save
exit
