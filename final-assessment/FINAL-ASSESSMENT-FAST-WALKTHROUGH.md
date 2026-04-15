# SEC-350 Final Assessment Fast Walkthrough (Suat)

This guide is optimized for speed and low rework. It uses your assigned IPs and script-first setup.

## Your IP map

- `edge01`: `10.0.17.115` (WAN), `172.16.50.2/29` (DMZ), `172.16.150.2/24` (LAN)
- `traveler` (`rw01`): `10.0.17.15` (WAN), `172.16.150.50/24` (LAN)
- `nginx`: `172.16.50.3/29`
- `jump`: `172.16.50.4/29`
- `log01`: `172.16.50.5/29`
- `wks01`: `172.16.150.50/24`
- `fw-mgmt`: `172.16.150.3/24` and `172.16.200.2/28`
- `mgmt01` (linux): `172.16.150.10/24`
- `wazuh` (mgmt): `172.16.200.10/28`
- `mgmt02` (windows): `172.16.200.11/28`
- `ca`: `172.16.200.12/28`

---

## 0) Put scripts on GitHub once

From your repo root:

```bash
cd ~/SEC-350-02-Enterprise-and-Network-Security-Controls
git add final-assessment
git commit -m "Add final assessment automation scripts and fast walkthrough"
git push origin main
```

On each VyOS firewall, run with:

```bash
curl -L -o /config/scripts/<name>.sh https://raw.githubusercontent.com/<your-user>/SEC-350-02-Enterprise-and-Network-Security-Controls/main/final-assessment/<name>.sh
chmod +x /config/scripts/<name>.sh
sudo /config/scripts/<name>.sh
```

Additional helper scripts in the same folder:

- `jump-hardening.sh`
- `nginx-https-waf.sh`
- `linux-wazuh-agent-enroll.sh`

Important:

- Both VyOS scripts contain `<HASHED_PASSWORD>` placeholders for required named local power users.
- Generate hash on VyOS with: `run mkpasswd -m sha-512`, then replace placeholder before running.

---

## 1) edge01 first (do this before anything else)

1. Log in to `edge01`.
2. Pull and run `edge01-bootstrap.sh`.
3. Validate:

```bash
show configuration commands | match "set system host-name"
show nat destination rules
show nat source rules
show configuration commands | match "firewall zone"
show configuration commands | match "WAN-LOCAL"
show ip route
```

Expected highlights:

- Hostname is `edge01`
- DNAT exists for `80,443 -> 172.16.50.3` and `22 -> 172.16.50.4`
- Static route `172.16.200.0/28` goes to `172.16.150.3`
- WAN local policy is present (so WAN ICMP to edge is blocked by default)
- DNS forwarding listens on DMZ/LAN and allows DMZ/LAN/MGMT
- RIP advertises DMZ network on `eth1`

---

## 2) fw-mgmt second

1. Log in to `fw-mgmt`.
2. Pull and run `fw-mgmt-bootstrap.sh`.
3. Validate:

```bash
show configuration commands | match "set system host-name"
show configuration commands | match "firewall zone"
show configuration commands | match "LAN-to-MGMT"
show ip route
```

Expected highlights:

- Hostname is `fw-mgmt`
- Route default next-hop is `172.16.150.2`
- MGMT and LAN zone policies are attached

---

## 3) mgmt02 and CA (separate hosts)

### 3.1 mgmt02 (172.16.200.11)

1. Rename host to `mgmt02`, set static IP `172.16.200.11/28`, gateway `172.16.200.2`.
2. Install AD DS and promote domain (example: `corp.local`).
3. Create named domain power admin user (for example `power-adm`) and use it for domain config tasks.
4. Configure DNS records for every host except traveler:
   - `edge01`, `nginx`, `jump`, `wks01`, `fw-mgmt`, `mgmt01`, `wazuh`, `mgmt02`

Quick checks:

- `nslookup edge01`
- `nslookup nginx`
- `ping fw-mgmt`

### 3.2 CA host (172.16.200.12)

1. Rename host to `ca`, set static IP `172.16.200.12/28`, gateway `172.16.200.2`, DNS `172.16.200.11`.
2. Join `ca` to the domain.
3. Install AD CS and issue certs for:
   - SSH auth/cert trust workflow for `jump` accounts
   - HTTPS server cert for `nginx`

---

## 4) jump host hardening + cert-based SSH

On `jump`:

```bash
curl -L -o /tmp/jump-hardening.sh https://raw.githubusercontent.com/<your-user>/SEC-350-02-Enterprise-and-Network-Security-Controls/main/final-assessment/jump-hardening.sh
chmod +x /tmp/jump-hardening.sh
sudo /tmp/jump-hardening.sh
```

Use CA-issued SSH cert workflow you were taught in class, then verify:

- `traveler -> jumpguest` is passwordless
- `mgmt VM -> jumpadmin` is passwordless
- default `guest` account is locked/disabled (show proof command)

---

## 5) nginx host + HTTPS + WAF

On `nginx`:

```bash
curl -L -o /tmp/nginx-https-waf.sh https://raw.githubusercontent.com/<your-user>/SEC-350-02-Enterprise-and-Network-Security-Controls/main/final-assessment/nginx-https-waf.sh
chmod +x /tmp/nginx-https-waf.sh
sudo NGINX_FQDN=nginx.corp.local CERT_PATH=/tmp/nginx.crt KEY_PATH=/tmp/nginx.key /tmp/nginx-https-waf.sh
```

Then:

1. Install CA-issued web cert for `nginx`.
2. Configure nginx TLS vhost on `443`.
3. Enable ModSecurity basic blocking mode.
4. Test from `wks01` by DNS name over HTTPS.
5. Confirm nginx cannot surf internet over DMZ->WAN TCP/443 (assessment requirement).

---

## 6) wks01 domain join + HTTPS proof

1. Set DNS to `mgmt02`.
2. Join AD domain.
3. Verify name resolution for all non-traveler hosts.
4. Browse `https://nginx` and show cert chain points to your CA.

---

## 7) Wazuh logging and MITRE detection

Goal from rubric:

- DMZ + LAN + MGMT hosts forward logs to Wazuh manager.
- Trigger one simple MITRE-mapped behavior and show it detected.

Manager IP for this environment: `172.16.200.10`.

Minimum host coverage to demonstrate:

- DMZ: `nginx`, `jump`, `log01`
- LAN: `mgmt01`, `wks01`
- MGMT: `mgmt02`, `ca`

Linux host enrollment helper:

```bash
curl -L -o /tmp/linux-wazuh-agent-enroll.sh https://raw.githubusercontent.com/<your-user>/SEC-350-02-Enterprise-and-Network-Security-Controls/main/final-assessment/linux-wazuh-agent-enroll.sh
chmod +x /tmp/linux-wazuh-agent-enroll.sh
sudo WAZUH_MANAGER=172.16.200.10 /tmp/linux-wazuh-agent-enroll.sh
```

Fast trigger suggestion:

- Multiple failed SSH attempts against `jump` from `traveler` or `mgmt01`.

Proof points:

- Agents connected in Wazuh dashboard.
- Alert tied to failed authentication / brute force behavior.

---

## 8) Final demo flow (15-20 min, one take)

1. Topology and IP map quick tour.
2. `edge01` rules + DNAT + blocked WAN ICMP proof.
3. `fw-mgmt` policy proof.
4. `mgmt02` AD DS + DNS + CA proof.
5. `jump` account/lockdown + passwordless SSH proof.
6. `nginx` HTTPS + WAF proof.
7. `wks01` domain joined + HTTPS reachability.
8. Wazuh MITRE alert proof.

---

## 9) Critical checks before recording

- From `traveler`, `ping 10.0.17.115` should fail (or be blocked) per WAN ICMP requirement.
- From `traveler`, `ssh <jumpguest>@10.0.17.115` should reach jump via DNAT.
- From `traveler`, browsing `http://10.0.17.115` and `https://10.0.17.115` should hit nginx.
- From `wks01`, `https://nginx` should work by DNS name with CA trust.
- Wazuh shows fresh events from DMZ, LAN, and MGMT hosts.
- From `nginx`, `curl https://www.champlain.edu` should fail/timeout due to DMZ egress restriction.

---

## 10) Required deltas covered by scripts

- `edge01-bootstrap.sh`: corrected MGMT route next-hop (`172.16.150.3`), WAN ICMP block via WAN local default drop, DNAT, DNS forwarding, RIP DMZ advertisement, and no broad DMZ outbound allow.
- `fw-mgmt-bootstrap.sh`: corrected fw-mgmt LAN IP (`172.16.150.3`), Wazuh target (`172.16.200.10`), and split handling for `mgmt02` vs `ca`.
- Both firewalls include named local power users (replace placeholder hash before execution).

