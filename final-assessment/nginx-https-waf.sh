#!/usr/bin/env bash
set -euo pipefail

# SEC-350 Final Assessment - nginx HTTPS + WAF baseline
# Run on nginx host as root/sudo.
#
# Required env vars:
#   NGINX_FQDN (example: nginx.corp.local)
#   CERT_PATH (path to fullchain cert, e.g. /tmp/nginx.crt)
#   KEY_PATH  (path to private key, e.g. /tmp/nginx.key)

: "${NGINX_FQDN:?Set NGINX_FQDN}"
: "${CERT_PATH:?Set CERT_PATH}"
: "${KEY_PATH:?Set KEY_PATH}"

sudo apt update
sudo apt install -y nginx libnginx-mod-http-modsecurity modsecurity-crs

echo "SEC-350 Final Assessment - Suat" | sudo tee /var/www/html/index.html >/dev/null

sudo install -d -m 755 /etc/nginx/ssl
sudo cp "${CERT_PATH}" /etc/nginx/ssl/nginx.crt
sudo cp "${KEY_PATH}" /etc/nginx/ssl/nginx.key
sudo chmod 600 /etc/nginx/ssl/nginx.key

sudo tee /etc/nginx/sites-available/default >/dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${NGINX_FQDN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name ${NGINX_FQDN};

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsec/main.conf;

    root /var/www/html;
    index index.html;
}
EOF

sudo install -d -m 755 /etc/nginx/modsec
sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
sudo sed -i "s/^SecRuleEngine .*/SecRuleEngine On/" /etc/nginx/modsec/modsecurity.conf
sudo tee /etc/nginx/modsec/main.conf >/dev/null <<'EOF'
Include /etc/nginx/modsec/modsecurity.conf
Include /usr/share/modsecurity-crs/crs-setup.conf
Include /usr/share/modsecurity-crs/rules/*.conf
EOF

sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "nginx HTTPS + WAF baseline complete."
