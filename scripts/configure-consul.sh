#!/usr/bin/env bash
set -e

source /vagrant/scripts/common.sh

HOST=$(hostname)

log "Configurando Consul en $HOST"

sudo mkdir -p /etc/consul.d
sudo mkdir -p /opt/consul

case "$HOST" in

    loadbalancer)

        IP="192.168.100.10"

        sudo tee /etc/consul.d/server.hcl >/dev/null <<EOF
datacenter = "dc1"

node_name = "loadbalancer"

server = true

bootstrap_expect = 1

data_dir = "/opt/consul"

bind_addr = "$IP"

client_addr = "0.0.0.0"

ui_config {
  enabled = true
}
EOF

        ;;


    web1)

        IP="192.168.100.11"

        sudo tee /etc/consul.d/client.hcl >/dev/null <<EOF
datacenter = "dc1"

node_name = "web1"

server = false

data_dir = "/opt/consul"

bind_addr = "$IP"

client_addr = "0.0.0.0"

retry_join = ["192.168.100.10"]
EOF

        ;;


    web2)

        IP="192.168.100.12"

        sudo tee /etc/consul.d/client.hcl >/dev/null <<EOF
datacenter = "dc1"

node_name = "web2"

server = false

data_dir = "/opt/consul"

bind_addr = "$IP"

client_addr = "0.0.0.0"

retry_join = ["192.168.100.10"]
EOF

        ;;


    *)

        echo "Hostname no soportado: $HOST"
        exit 1
        ;;

esac


sudo chown -R consul:consul /etc/consul.d
sudo chown -R consul:consul /opt/consul

log "Validando configuracion Consul"

sudo consul validate /etc/consul.d

sudo systemctl enable consul

log "Reiniciando Consul"

sudo systemctl restart consul

sleep 5

sudo systemctl is-active --quiet consul

echo "Consul funcionando correctamente en $HOST"