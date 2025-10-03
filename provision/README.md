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

For working with Docker Compose, use:
```bash
alias dc='dotenv -e .env.production docker-compose -f docker-compose.production.yml'
```
