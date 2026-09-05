#!/usr/bin/env bash
set -e

source /vagrant/scripts/common.sh

install_common_packages

log "Instalacion de Consul"

if command -v consul >/dev/null 2>&1; then
    echo "Consul ya esta instalado:"
    consul version
    exit 0
fi

wget -O- https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    >/dev/null

echo \
"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y consul

sudo mkdir -p /etc/consul.d
sudo mkdir -p /opt/consul

sudo chown -R consul:consul /etc/consul.d
sudo chown -R consul:consul /opt/consul

consul version