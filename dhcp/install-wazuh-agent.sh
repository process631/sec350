#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./install-wazuh-agent.sh <WAZUH_MANAGER_HOSTNAME_OR_IP>
# Example:
#   sudo ./install-wazuh-agent.sh wazuh-suat.gungor

if [[ $# -ne 1 ]]; then
  echo "Usage: sudo $0 <WAZUH_MANAGER_HOSTNAME_OR_IP>"
  exit 1
fi

WAZUH_MANAGER="$1"

curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH \
  | gpg --dearmor \
  | tee /usr/share/keyrings/wazuh.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list

apt update
WAZUH_MANAGER="$WAZUH_MANAGER" apt install -y wazuh-agent
systemctl enable --now wazuh-agent
systemctl status wazuh-agent --no-pager
