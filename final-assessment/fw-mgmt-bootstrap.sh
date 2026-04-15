#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# SEC-350 Final Assessment - fw-mgmt bootstrap
# Assumed mapping:
#   eth0 = LAN (172.16.150.3/24)
#   eth1 = MGMT (172.16.200.2/28)
# Update interface names/addresses below only if your VM differs.

configure

set system host-name 'fw-mgmt'

set interfaces ethernet eth0 description 'LAN'
set interfaces ethernet eth0 address '172.16.150.3/24'
set interfaces ethernet eth1 description 'MGMT'
set interfaces ethernet eth1 address '172.16.200.2/28'

# ---- Local named power user (assessment requirement) ----
# Replace <HASHED_PASSWORD> with a real encrypted password string before running.
set system login user 'powermgmt' full-name 'FW-MGMT Power User'
set system login user 'powermgmt' authentication encrypted-password '<HASHED_PASSWORD>'

# Default route back to edge01 for internet-bound traffic
set protocols static route 0.0.0.0/0 next-hop '172.16.150.2'

# NAT MGMT outbound through LAN side (so mgmt net can reach updates if needed)
delete nat source rule 100
set nat source rule 100 description 'MGMT outbound NAT'
set nat source rule 100 outbound-interface name 'eth0'
set nat source rule 100 source address '172.16.200.0/28'
set nat source rule 100 translation address 'masquerade'

delete firewall ipv4 name LAN-to-MGMT
set firewall ipv4 name LAN-to-MGMT description 'LAN to MGMT policy'
set firewall ipv4 name LAN-to-MGMT default-action 'drop'
set firewall ipv4 name LAN-to-MGMT default-log
set firewall ipv4 name LAN-to-MGMT rule 1 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 1 state 'established'
set firewall ipv4 name LAN-to-MGMT rule 1 state 'related'
set firewall ipv4 name LAN-to-MGMT rule 10 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 10 description 'Allow AD/DNS/CA access from LAN clients'
set firewall ipv4 name LAN-to-MGMT rule 10 protocol 'tcp_udp'
set firewall ipv4 name LAN-to-MGMT rule 10 destination address '172.16.200.11'
set firewall ipv4 name LAN-to-MGMT rule 10 destination port '53,88,135,389,445,464,636,3268,3269,49152-65535'
set firewall ipv4 name LAN-to-MGMT rule 20 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 20 description 'Allow HTTPS/WinRM to mgmt02 admin host'
set firewall ipv4 name LAN-to-MGMT rule 20 destination address '172.16.200.11'
set firewall ipv4 name LAN-to-MGMT rule 20 protocol 'tcp'
set firewall ipv4 name LAN-to-MGMT rule 20 destination port '443,5985,5986'
set firewall ipv4 name LAN-to-MGMT rule 25 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 25 description 'Allow CA web enrollment on dedicated CA host'
set firewall ipv4 name LAN-to-MGMT rule 25 destination address '172.16.200.12'
set firewall ipv4 name LAN-to-MGMT rule 25 protocol 'tcp'
set firewall ipv4 name LAN-to-MGMT rule 25 destination port '80,443'
set firewall ipv4 name LAN-to-MGMT rule 30 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 30 description 'Allow logs to Wazuh manager'
set firewall ipv4 name LAN-to-MGMT rule 30 destination address '172.16.200.10'
set firewall ipv4 name LAN-to-MGMT rule 30 protocol 'tcp'
set firewall ipv4 name LAN-to-MGMT rule 30 destination port '1514-1515,55000'
set firewall ipv4 name LAN-to-MGMT rule 40 action 'accept'
set firewall ipv4 name LAN-to-MGMT rule 40 description 'Allow DMZ Wazuh agents via edge01'
set firewall ipv4 name LAN-to-MGMT rule 40 source address '172.16.50.0/29'
set firewall ipv4 name LAN-to-MGMT rule 40 destination address '172.16.200.10'
set firewall ipv4 name LAN-to-MGMT rule 40 protocol 'tcp'
set firewall ipv4 name LAN-to-MGMT rule 40 destination port '1514-1515'

delete firewall ipv4 name MGMT-to-LAN
set firewall ipv4 name MGMT-to-LAN description 'MGMT to LAN policy'
set firewall ipv4 name MGMT-to-LAN default-action 'drop'
set firewall ipv4 name MGMT-to-LAN default-log
set firewall ipv4 name MGMT-to-LAN rule 1 action 'accept'
set firewall ipv4 name MGMT-to-LAN rule 1 state 'established'
set firewall ipv4 name MGMT-to-LAN rule 1 state 'related'
set firewall ipv4 name MGMT-to-LAN rule 10 action 'accept'
set firewall ipv4 name MGMT-to-LAN rule 10 description 'Allow mgmt admins to manage LAN'
set firewall ipv4 name MGMT-to-LAN rule 10 protocol 'tcp'
set firewall ipv4 name MGMT-to-LAN rule 10 destination port '22,3389,5985,5986'
set firewall ipv4 name MGMT-to-LAN rule 20 action 'accept'
set firewall ipv4 name MGMT-to-LAN rule 20 description 'Allow DNS responses and queries'
set firewall ipv4 name MGMT-to-LAN rule 20 protocol 'tcp_udp'
set firewall ipv4 name MGMT-to-LAN rule 20 destination port '53'

delete firewall ipv4 name MGMT-to-WAN
set firewall ipv4 name MGMT-to-WAN description 'MGMT to WAN policy'
set firewall ipv4 name MGMT-to-WAN default-action 'drop'
set firewall ipv4 name MGMT-to-WAN default-log
set firewall ipv4 name MGMT-to-WAN rule 1 action 'accept'
set firewall ipv4 name MGMT-to-WAN rule 1 state 'established'
set firewall ipv4 name MGMT-to-WAN rule 1 state 'related'
set firewall ipv4 name MGMT-to-WAN rule 10 action 'accept'
set firewall ipv4 name MGMT-to-WAN rule 10 description 'Allow mgmt outbound as needed'

delete firewall ipv4 name WAN-to-MGMT
set firewall ipv4 name WAN-to-MGMT description 'LAN transit toward MGMT'
set firewall ipv4 name WAN-to-MGMT default-action 'drop'
set firewall ipv4 name WAN-to-MGMT default-log
set firewall ipv4 name WAN-to-MGMT rule 1 action 'accept'
set firewall ipv4 name WAN-to-MGMT rule 1 state 'established'
set firewall ipv4 name WAN-to-MGMT rule 1 state 'related'

set firewall zone LAN description 'LAN zone'
set firewall zone LAN member interface 'eth0'
set firewall zone LAN from MGMT firewall name 'MGMT-to-LAN'

set firewall zone MGMT description 'MGMT zone'
set firewall zone MGMT member interface 'eth1'
set firewall zone MGMT from LAN firewall name 'LAN-to-MGMT'

commit
save
exit
