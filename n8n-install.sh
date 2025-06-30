#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Instalando dependencias"
$STD apt-get install -y ca-certificates
msg_ok "Dependencias instaladas"

msg_info "Instalando Node.js v22"
NODE_VERSION="22" setup_nodejs
msg_ok "Node.js instalado"

msg_info "Instalando n8n y herramientas necesarias"
$STD npm install --global patch-package
$STD npm install --global n8n
msg_ok "n8n instalado"

msg_info "Creando estructura de configuración"
mkdir -p /data/n8n
mkdir -p /data/local-files
mkdir -p /etc/n8n

cat <<EOF >/etc/n8n/.env
N8N_SECURE_COOKIE=true
N8N_USER_FOLDER=/data/n8n
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_HOST=n8n.dominio.algo
WEBHOOK_URL=https://n8n.dominio.algo/
NODE_ENV=production
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=tuadminpapi
N8N_BASIC_AUTH_PASSWORD=lamismadesiempre
N8N_RUNNERS_ENABLED=true
GENERIC_TIMEZONE=America/Lima
EOF
msg_ok "Estructura creada y archivo .env configurado"

msg_info "Creando servicio systemd"
cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/n8n/.env
ExecStart=/usr/bin/n8n start
WorkingDirectory=/data/n8n
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now n8n
msg_ok "Servicio creado y activo"

motd_ssh
customize

msg_info "Limpiando sistema"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Limpieza completa"
