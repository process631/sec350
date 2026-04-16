#!/usr/bin/env bash
set -euo pipefail

# SSH certificate enrollment helper for Jump host
# Sends your public key to mgmt02 CA, requests signing, then retrieves cert.

# Configuration (override with env vars if needed)
CA_USER="${CA_USER:-administrator}"
CA_HOST="${CA_HOST:-172.16.200.11}"
USER_KEY="${USER_KEY:-$HOME/.ssh/id_ed25519.pub}"
CERT_FILE="${CERT_FILE:-$HOME/.ssh/id_ed25519-cert.pub}"
CA_SIGNING_KEY="${CA_SIGNING_KEY:-C:/ProgramData/ssh/ca/ssh_user_key}"
CA_SSH_KEYGEN="${CA_SSH_KEYGEN:-C:/Windows/System32/OpenSSH/ssh-keygen.exe}"
CERT_ID="${CERT_ID:-jump-host}"
CERT_PRINCIPAL="${CERT_PRINCIPAL:-champuser}"
CERT_VALIDITY="${CERT_VALIDITY:-+52w}"
REMOTE_KEY="${REMOTE_KEY:-C:/temp/jump_key.pub}"
REMOTE_CERT="${REMOTE_CERT:-C:/temp/jump_key-cert.pub}"

echo "Starting SSH certificate enrollment..."

if [[ ! -f "$USER_KEY" ]]; then
  echo "[-] Public key not found: $USER_KEY"
  exit 1
fi

# 1) Push public key to CA host
echo "[*] Sending public key to CA..."
scp "$USER_KEY" "${CA_USER}@${CA_HOST}:${REMOTE_KEY}"

# 2) Ask CA host to sign the public key
echo "[*] Requesting CA signature..."
ssh "${CA_USER}@${CA_HOST}" "\"${CA_SSH_KEYGEN}\" -s ${CA_SIGNING_KEY} -I ${CERT_ID} -n ${CERT_PRINCIPAL} -V ${CERT_VALIDITY} ${REMOTE_KEY}"

# 3) Retrieve signed certificate
echo "[*] Retrieving signed certificate..."
scp "${CA_USER}@${CA_HOST}:${REMOTE_CERT}" "$CERT_FILE"

# 4) Permissions + verify
chmod 644 "$CERT_FILE"

if [[ -f "$CERT_FILE" ]]; then
  echo "[+] Success! Certificate received: $CERT_FILE"
  ssh-keygen -L -f "$CERT_FILE" | grep -E 'Principals|Valid'
else
  echo "[-] Error: Certificate enrollment failed."
  exit 1
fi

