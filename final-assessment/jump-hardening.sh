#!/usr/bin/env bash
set -euo pipefail

# SEC-350 Final Assessment - jump hardening baseline
# Run on jump as root/sudo.

GUEST_USER="${GUEST_USER:-jumpguest}"
ADMIN_USER="${ADMIN_USER:-jumpadmin}"

if ! id -u "${GUEST_USER}" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash "${GUEST_USER}"
fi

if ! id -u "${ADMIN_USER}" >/dev/null 2>&1; then
  sudo useradd -m -s /bin/bash "${ADMIN_USER}"
fi

# Lock default guest account if present
if id -u guest >/dev/null 2>&1; then
  sudo passwd -l guest || true
fi

for user in "${GUEST_USER}" "${ADMIN_USER}"; do
  sudo install -d -m 700 -o "${user}" -g "${user}" "/home/${user}/.ssh"
  sudo touch "/home/${user}/.ssh/authorized_keys"
  sudo chown "${user}:${user}" "/home/${user}/.ssh/authorized_keys"
  sudo chmod 600 "/home/${user}/.ssh/authorized_keys"
done

sudo systemctl enable ssh
sudo systemctl restart ssh

echo "Jump baseline complete."
echo "Next: enroll SSH cert/keys from CA and test passwordless logins."
