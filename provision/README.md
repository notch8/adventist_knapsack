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
   - SSL certificate: `b2_adventistdigitallibrary_org_2024_complete.cer`
   - SSL private key: `b2.adventistdigitallibrary.org.2024.key`
   - Nginx config: `nginx-default`
   - Deploy key: `id_rsa`

## Installation

1. Install Ansible dependencies:
```bash
ansible-galaxy collection install community.docker
ansible-galaxy install -r requirements.yml
```

2. Update the inventory file with your server's IP address

3. Run the playbook:
```bash
ansible-playbook -i inventory.yml site.yml
```

## What Gets Installed

The playbook will:
- Create and mount storage directories
- Install Docker, Nginx, and other required packages
- Configure SSL certificates
- Set up Nginx with bad bot blocker
- Create user accounts with SSH access
- Configure Docker registry access
- Set up deployment keys

## Post-Installation

Application deploys (as opposed to this host provisioning) are handled by
`bin/deploy` at the repo root - see [ops/DEPLOY.md](../ops/DEPLOY.md). For a
one-off manual Docker Compose command against a specific environment:
```bash
# Not a plain alias - the installed python3-dotenv-cli (2.2.0) doesn't merge
# multiple -e files (passing two silently drops the first file's keys), so
# this loads both into the shell directly instead. A function, not an alias,
# since it needs multiple statements.
dc() { set -a; source .env.common; source .env.production; set +a; docker-compose -f docker-compose.production.yml "$@"; }
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
