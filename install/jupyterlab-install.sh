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

msg_info "Installing Git"
$STD apt-get install -y git
msg_ok "Installed Git"

msg_info "Installing JupyterLab"
mkdir -p /opt/jupyter
cd /opt/jupyter
$STD uv venv .venv
$STD uv pip install pip
$STD uv pip install jupyterlab jupyterlab-git
ln -s /opt/jupyter/.venv/bin/jupyter /usr/local/bin/jupyter
ln -s /opt/jupyter/.venv/bin/jupyter-lab /usr/local/bin/jupyter-lab
msg_ok "Installed JupyterLab"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/jupyterlab.service
[Unit]
Description=JupyterLab Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/jupyter
ExecStart=/opt/jupyter/.venv/bin/jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now jupyterlab
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
