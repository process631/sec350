#!/bin/vbash
# Lab 9.1 — Ad hoc VPN (SSH) / RDP path: allow DMZ → mgmt02 RDP through edge01.
# Intended for VyOS on edge01. Run: sudo ./lab9-dmz-to-lan-rdp.sh
#
# Adds DMZ-to-LAN rule 15: TCP/3389 from jump (172.16.50.4) to mgmt02 (172.16.200.11).
# If rule 15 already exists, delete it first: configure; delete firewall ipv4 name DMZ-to-LAN rule 15; commit; save
#
# IPs match Suat row / course sheet; change SOURCE/DEST if your assignment differs.

source /opt/vyatta/etc/functions/script-template

configure
set firewall ipv4 name DMZ-to-LAN rule 15 protocol 'tcp'
set firewall ipv4 name DMZ-to-LAN rule 15 source address '172.16.50.4'
set firewall ipv4 name DMZ-to-LAN rule 15 destination address '172.16.200.11'
set firewall ipv4 name DMZ-to-LAN rule 15 destination port '3389'
set firewall ipv4 name DMZ-to-LAN rule 15 action 'accept'
set firewall ipv4 name DMZ-to-LAN rule 15 description 'Lab 9.1 RDP jump to mgmt02'
commit
save
exit
