#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "======================================"
echo " Configurando LOAD BALANCER"
echo "======================================"

sudo apt-get update

sudo apt-get install -y \
  haproxy \
  dnsutils \
  curl

# --------------------------------------
# CONSUL SERVER
# --------------------------------------

sudo tee /etc/consul.d/server.hcl >/dev/null <<'EOF'
datacenter = "dc1"
node_name  = "loadbalancer"

server = true
bootstrap_expect = 1

data_dir = "/opt/consul"

bind_addr   = "192.168.100.10"
client_addr = "0.0.0.0"

ui_config {
  enabled = true
}
EOF

sudo chown -R consul:consul /etc/consul.d
sudo chown -R consul:consul /opt/consul

sudo consul validate /etc/consul.d

sudo systemctl enable consul
sudo systemctl restart consul

# --------------------------------------
# HAPROXY
# --------------------------------------

sudo mkdir -p /etc/haproxy/errors

sudo cp /vagrant/haproxy/haproxy.cfg \
  /etc/haproxy/haproxy.cfg

sudo cp /vagrant/haproxy/errors/503.http \
  /etc/haproxy/errors/503.http

sudo haproxy -c -f /etc/haproxy/haproxy.cfg

sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "======================================"
echo " Load balancer configurado"
echo "======================================"