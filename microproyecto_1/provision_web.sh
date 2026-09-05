#!/bin/bash
IP=$1

echo "=== Optimizando red y limpiando cache ==="
# Forzar IPv4 para evitar timeouts en Vagrant
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean
sudo apt-get update

echo "=== Instalando Consul ==="
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update
sudo apt-get install consul -y

echo "=== Instalando NodeJS 20 (Versión Oficial Limpia) ==="
# Nos aseguramos de borrar cualquier versión vieja y corrupta de Ubuntu
sudo apt-get remove -y nodejs npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
# La versión de NodeSource ya incluye npm internamente, no hay que pedirlo aparte
sudo apt-get install -y nodejs

echo "=== Configurando Consul Agent (Cliente) ==="
mkdir -p /etc/consul.d
cat <<EOF > /etc/consul.d/client.json
{
  "server": false,
  "client_addr": "0.0.0.0",
  "bind_addr": "${IP}",
  "retry_join": ["192.168.100.2"],
  "data_dir": "/var/lib/consul"
}
EOF
nohup consul agent -config-dir=/etc/consul.d > /var/log/consul.log 2>&1 &

echo "=== Preparando la app NodeJS ==="
mkdir -p /home/vagrant/app
cd /home/vagrant/app
npm install consul express