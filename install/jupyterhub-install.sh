#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Ricoter
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jupyter.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Dependencies"
$STD apt-get install -y \
    git \
    nodejs \
    npm
msg_ok "Installed Dependencies"
msg_info "Installing JupyterHub"
mkdir -p /opt/jupyterhub
cd /opt/jupyterhub

# Get latest JupyterHub version
RELEASE=$(curl -fsSL https://pypi.org/pypi/jupyterhub/json | grep -Po '"version":.*?[^\\]",' | head -1 | cut -d'"' -f4)

$STD uv venv .venv
$STD uv pip install pip
$STD uv pip install jupyterhub=="${RELEASE}" jupyterlab
$STD npm install -g configurable-http-proxy
ln -s /opt/jupyterhub/.venv/bin/jupyterhub /usr/local/bin/jupyterhub

# Save version for future update checks
echo "${RELEASE}" >/opt/jupyterhub_version.txt
msg_ok "Installed JupyterHub"

msg_info "Creating JupyterHub Configuration"
cat <<EOF >/opt/jupyterhub/jupyterhub_config.py
# JupyterHub Configuration File
import os

c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000
c.JupyterHub.hub_ip = '0.0.0.0'

# Default to JupyterLab
c.Spawner.default_url = '/lab'

# Admin user
c.Authenticator.admin_users = {'admin'}
c.Authenticator.allow_all = True

c.Spawner.notebook_dir = '~'
c.Spawner.cmd = ['/opt/jupyterhub/.venv/bin/jupyter-labhub']

c.JupyterHub.log_level = 'INFO'
EOF
msg_ok "Created JupyterHub Configuration"

msg_info "Creating Admin User"
ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
useradd -m -s /bin/bash admin
echo "admin:${ADMIN_PASS}" | chpasswd

{
    echo "JupyterHub Credentials"
    echo "Username: admin"
    echo "Password: ${ADMIN_PASS}"
} >>~/jupyterhub.creds
msg_ok "Created Admin User"

msg_info "Setting Permissions"
chown -R root: /opt/jupyterhub
chmod -R 755 /opt/jupyterhub
msg_ok "Permissions Set"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jupyterhub.service
[Unit]
Description=JupyterHub Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/jupyterhub
ExecStart=/opt/jupyterhub/.venv/bin/jupyterhub -f /opt/jupyterhub/jupyterhub_config.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jupyterhub
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
