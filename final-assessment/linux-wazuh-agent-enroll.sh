#!/usr/bin/env bash
set -euo pipefail

# SEC-350 Final Assessment - Linux Wazuh enroll helper
# Run on each Linux host that should send logs (DMZ/LAN/MGMT).
#
# Required env var:
#   WAZUH_MANAGER (default for this environment: 172.16.200.10)

WAZUH_MANAGER="${WAZUH_MANAGER:-172.16.200.10}"

if ! command -v systemctl >/dev/null 2>&1; then
  echo "This script expects a systemd-based Linux host."
  exit 1
fi

if [ ! -f /var/ossec/etc/ossec.conf ]; then
  echo "Wazuh agent not installed; install it first, then re-run."
  exit 1
fi

sudo sed -i -E "s#<address>.*</address>#<address>${WAZUH_MANAGER}</address>#g" /var/ossec/etc/ossec.conf
sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent
sudo systemctl --no-pager --full status wazuh-agent || true

echo "Configured Wazuh manager as ${WAZUH_MANAGER}."
