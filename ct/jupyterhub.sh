#!/usr/bin/env bash
# source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
source <(curl -fsSL https://raw.githubusercontent.com/Ricoter/ProxmoxVED/refs/heads/JupyterHub-branch/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Ricoter
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jupyter.org/

APP="JupyterHub"
var_tags="${var_tags:-development;jupyter;multi-user}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/jupyterhub ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://pypi.org/pypi/jupyterhub/json | grep -Po '"version":.*?[^\\]",' | head -1 | cut -d'"' -f4)

    if [[ ! -f /opt/jupyterhub_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/jupyterhub_version.txt)" ]]; then
        msg_info "Updating ${APP} to v${RELEASE}"

        systemctl stop jupyterhub

        cp /opt/jupyterhub/jupyterhub_config.py /opt/jupyterhub_config.py.backup

        cd /opt/jupyterhub
        $STD uv pip install --upgrade jupyterhub=="${RELEASE}" jupyterlab
        $STD npm update -g configurable-http-proxy

        # Restore configuration
        cp /opt/jupyterhub_config.py.backup /opt/jupyterhub/jupyterhub_config.py

        # Update version file
        echo "${RELEASE}" > /opt/jupyterhub_version.txt

        # Start service
        systemctl start jupyterhub

        # Cleanup
        rm -f /opt/jupyterhub_config.py.backup

        msg_ok "Updated ${APP} to v${RELEASE}"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi

    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW} Login with credentials from ~/jupyterhub.creds${CL}"
