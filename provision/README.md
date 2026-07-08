# Adventist Server Setup

This repository contains Ansible playbooks to automate the setup of the Adventist server.

## Prerequisites

1. Clone the keep volume
2. Clone the tmp volume
3. NAD Cloud to generate new instance and give Notch8 access via ssh to setup ansible provision of infrastructure.
4. NAD Cloud to provision and attach the volumes to the instance:
   - tmp: 800 GiB
   - keep: 4000 GiB
   - 100 GiB
5. Set up 1password cli (`op`) OR place required files in the `files/` directory:
   - Deploy key: `id_rsa`
   - GHCR token: `ghcr_token`
   - Ansible become password: `ansible_become_password`
   - Cloudflare credentials: `cloudflare.ini`
   - If using the run script to fetch secrets from 1Password, sign in first: `eval $(op signin)`

## Installation

1. Install Ansible dependencies:
```bash
ansible-galaxy collection install community.docker
ansible-galaxy collection install ansible.posix
ansible-galaxy install -r requirements.yml
```

2. Update the inventory file with your server's IP address

3. Run the playbook:
```bash
# Using the run script (recommended - handles 1Password secrets automatically)
cd provision
./bin/run staging    # For staging environment
./bin/run production # For production environment

# Or manually:
ansible-playbook -i inventory.yml site.yml -e "env=staging" --limit staging
ansible-playbook -i inventory.yml site.yml -e "env=production" --limit production
```

## What Gets Installed

The playbook will:
- Create and mount storage directories
- Install Docker, Nginx, Certbot, and other required packages
- Generate SSL certificates via Let's Encrypt with Cloudflare DNS validation
- Set up Nginx with bad bot blocker
- Create user accounts with SSH access
- Configure Docker registry access
- Set up deployment keys

---

## SSL Certificate Management

### How It Works

Certificates are generated using **Certbot with Cloudflare DNS-01 challenge**. This allows wildcard certificates for subdomains.

The certificate configuration is defined in `vars/main.yml`:

```yaml
environments:
  staging:
    hostnames:
      - s2.adventistdigitallibrary.org
      - '*.s2.adventistdigitallibrary.org'
    ssl_cert_dest: /etc/letsencrypt/archive/s2.adventistdigitallibrary.org/fullchain1.pem
    ssl_key_dest: /etc/letsencrypt/archive/s2.adventistdigitallibrary.org/privkey1.pem
  production:
    hostnames:
      - b2.adventistdigitallibrary.org
      - '*.b2.adventistdigitallibrary.org'
    ssl_cert_dest: /etc/letsencrypt/archive/b2.adventistdigitallibrary.org/fullchain1.pem
    ssl_key_dest: /etc/letsencrypt/archive/b2.adventistdigitallibrary.org/privkey1.pem
```

### When the cert is down or expired

The playbook **skips** certificate generation if a cert already exists (idempotent task). So if the cert is expired or broken:

1. **Remove the old cert on the server** (use the hostname for your environment: `s2` for staging, `b2` for production):

   **Staging:**
   ```bash
   ssh adlquantum6269@192.168.147.200
   sudo rm -rf /etc/letsencrypt/live/s2.adventistdigitallibrary.org
   sudo rm -rf /etc/letsencrypt/archive/s2.adventistdigitallibrary.org
   sudo rm -f /etc/letsencrypt/renewal/s2.adventistdigitallibrary.org.conf
   exit
   ```

   **Production:**
   ```bash
   ssh adlquantum6269@192.168.147.100
   sudo rm -rf /etc/letsencrypt/live/b2.adventistdigitallibrary.org
   sudo rm -rf /etc/letsencrypt/archive/b2.adventistdigitallibrary.org
   sudo rm -f /etc/letsencrypt/renewal/b2.adventistdigitallibrary.org.conf
   exit
   ```

2. **Ensure `files/cloudflare.ini` exists** (run script fetches from 1Password if missing; or create it with `dns_cloudflare_api_token = YOUR_TOKEN`).

3. **Run the playbook** (or only cert + nginx):
   ```bash
   cd provision
   ./bin/run staging    # or production
   # Or just cert + nginx:
   ansible-playbook -i inventory.yml site.yml -e "env=staging" --limit staging --tags "certbot,nginx"
   ```

4. **Verify:** on the server run `sudo certbot certificates` or use the openssl check in "Verify Certificate" below.

### Changing Domains (e.g., s3/b3 → s2/b2)

When you need to change domains, follow these steps:

#### 1. Update `vars/main.yml`

Edit the `hostnames`, `hyku_admin_host`, and SSL paths for the environment:

```yaml
environments:
  staging:
    hyku_admin_host: s2.adventistdigitallibrary.org  # Change this
    hostnames:
      - s2.adventistdigitallibrary.org               # Change this
      - '*.s2.adventistdigitallibrary.org'           # Change this
    ssl_cert_dest: /etc/letsencrypt/archive/s2.adventistdigitallibrary.org/fullchain1.pem
    ssl_key_dest: /etc/letsencrypt/archive/s2.adventistdigitallibrary.org/privkey1.pem
```

#### 2. Ensure Cloudflare Credentials Are Set

The `files/cloudflare.ini` file should contain:

```ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
```

This token needs permissions to manage DNS records for the domain.

#### 3. Force Certificate Regeneration

The ansible task uses `creates:` to skip if a cert already exists. To force regeneration:

**Option A: Remove old cert on server first**

Replace `OLD_DOMAIN` with the old subdomain (e.g. `s3` or `s2`). For current staging use `s2`, for production use `b2`.

```bash
# SSH to the server
ssh adlquantum6269@192.168.147.200  # staging
ssh adlquantum6269@192.168.147.100  # production

# Remove old certificate (use actual hostname, e.g. s2 or b2 or OLD_DOMAIN)
sudo rm -rf /etc/letsencrypt/live/OLD_DOMAIN.adventistdigitallibrary.org
sudo rm -rf /etc/letsencrypt/archive/OLD_DOMAIN.adventistdigitallibrary.org
sudo rm -f /etc/letsencrypt/renewal/OLD_DOMAIN.adventistdigitallibrary.org.conf
```

**Option B: Run certbot manually with `--force-renewal`**
```bash
# On the server
sudo certbot certonly --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
  --non-interactive --agree-tos \
  -m admin@adventistdigitallibrary.org \
  --force-renewal \
  -d s2.adventistdigitallibrary.org \
  -d '*.s2.adventistdigitallibrary.org'
```

#### 4. Run the Ansible Playbook

```bash
cd provision
./bin/run staging     # For staging
./bin/run production  # For production
```

Or to run just the certbot and nginx tasks:

```bash
ansible-playbook -i inventory.yml site.yml -e "env=staging" --limit staging --tags "certbot,nginx"
```

#### 5. Verify Certificate

```bash
# On the server
sudo certbot certificates

# Or test with openssl
echo | openssl s_client -servername s2.adventistdigitallibrary.org -connect localhost:443 2>/dev/null | openssl x509 -noout -dates -subject
```

### Certificate Renewal

Certificates auto-renew via a cron job set up by the playbook:
```
0 3 * * * certbot renew --quiet && systemctl reload nginx
```

To manually renew:
```bash
sudo certbot renew
sudo systemctl reload nginx
```

### Troubleshooting

**Certificate not generating:**
- Check Cloudflare API token permissions
- Verify DNS is properly configured for the domain
- Check certbot logs: `sudo cat /var/log/letsencrypt/letsencrypt.log`

**"Incorrect TXT record" / "Some challenges have failed" (stale ACME challenge):**  
Let's Encrypt is seeing an old `_acme-challenge` TXT record that doesn't match the current challenge. In Cloudflare DNS for the zone (e.g. adventistdigitallibrary.org):
1. Go to **DNS** → **Records**.
2. Find and **delete** any `_acme-challenge.s2.adventistdigitallibrary.org` or `_acme-challenge` (subdomain s2 or b2) TXT records.
3. Wait a minute, then re-run the playbook with `--tags certbot,nginx`. The playbook now waits 90 seconds for propagation; if it still fails, delete the TXT record again and re-run (sometimes multiple old values exist).

**Nginx won't start:**
- Certificate path mismatch - ensure `ssl_cert_dest` and `ssl_key_dest` in vars match actual cert location
- Check nginx config: `sudo nginx -t`

**Wildcard not working:**
- Ensure the wildcard hostname uses quotes: `'*.s2.adventistdigitallibrary.org'`
- DNS-01 challenge is required for wildcards (HTTP-01 won't work)

---

## Post-Installation

Application deploys (as opposed to this host provisioning) are handled by
`bin/deploy` at the repo root - see [ops/DEPLOY.md](../ops/DEPLOY.md). For a
one-off manual Docker Compose command against a specific environment:
```bash
alias dc='dotenv -o -f .env.production,.env.common docker compose -f docker-compose.production.yml'
# (swap .env.production / docker-compose.production.yml for .env.staging / docker-compose.staging.yml on staging)
```

## File Structure

```
provision/
├── bin/
│   └── run                    # Main deployment script
├── files/
│   ├── ansible_become_password # sudo password (gitignored content)
│   ├── cloudflare.ini          # Cloudflare API credentials (gitignored content)
│   ├── ghcr_token              # GitHub Container Registry token
│   ├── id_rsa                  # SSH deploy key (gitignored)
│   ├── id_rsa.pub              # SSH public key
│   └── nginx-default.j2        # Nginx config template
├── roles/
│   └── base_setup/             # Base system setup role
├── vars/
│   └── main.yml                # Environment-specific variables
├── inventory.yml               # Server inventory
├── requirements.yml            # Ansible role dependencies
└── site.yml                    # Main playbook
```
