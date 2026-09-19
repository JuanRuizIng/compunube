#!/bin/bash
# SERVIDOR WEB 2 - Consul Client + NodeJS

# 1. Instalar Node.js 20 y Consul
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y && sudo apt-get install -y consul git

# 2. Configurar y arrancar Consul Client
sudo mkdir -p /opt/consul
cat <<EOF | sudo tee /etc/consul.d/consul.hcl
datacenter  = "dc1"
data_dir    = "/opt/consul"
bind_addr   = "192.168.100.2"
client_addr = "0.0.0.0"
server      = false
retry_join  = ["192.168.100.3"]
EOF
sudo systemctl enable consul && sudo systemctl restart consul

# 3. Descargar app, ajustar IP de registro e instalar dependencias
if [ ! -d "/home/vagrant/consulService" ]; then
    git clone https://github.com/omondragon/consulService /home/vagrant/consulService
fi
cd /home/vagrant/consulService/app
sed -i "s/192.168.100.3/192.168.100.2/g" index.js
npm install consul express
