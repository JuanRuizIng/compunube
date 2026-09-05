#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "web1" ]; then
    IP="192.168.100.11"
elif [ "$HOSTNAME" = "web2" ]; then
    IP="192.168.100.12"
else
    echo "Hostname no reconocido: $HOSTNAME"
    exit 1
fi

echo "======================================"
echo " Configurando servidor $HOSTNAME"
echo " IP: $IP"
echo "======================================"

# --------------------------------------
# NODEJS 20
# --------------------------------------

CURRENT_NODE_MAJOR=""

if command -v node >/dev/null 2>&1; then
    CURRENT_NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]" || true)
fi

if [ "$CURRENT_NODE_MAJOR" != "20" ]; then

    echo "Instalando NodeJS 20..."

    sudo apt-get remove -y nodejs libnode-dev || true
    sudo apt-get autoremove -y || true
    sudo dpkg --configure -a
    sudo apt-get --fix-broken install -y

    curl -fsSL https://deb.nodesource.com/setup_20.x \
      | sudo -E bash -

    sudo apt-get install -y nodejs

fi

node --version
npm --version

# --------------------------------------
# APLICACION
# --------------------------------------

sudo mkdir -p /opt/nodeapp

sudo cp /vagrant/webapp/server.js /opt/nodeapp/server.js
sudo cp /vagrant/webapp/package.json /opt/nodeapp/package.json

sudo chown -R vagrant:vagrant /opt/nodeapp

cd /opt/nodeapp

sudo -u vagrant npm install

# --------------------------------------
# SYSTEMD - PUERTO 3000
# --------------------------------------

sudo tee /etc/systemd/system/nodeapp.service >/dev/null <<'EOF'
[Unit]
Description=Microproyecto NodeJS principal
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/opt/nodeapp
ExecStart=/usr/bin/node /opt/nodeapp/server.js
Restart=always
RestartSec=3
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------
# SYSTEMD - PUERTO 3001
# --------------------------------------

sudo tee /etc/systemd/system/nodeapp2.service >/dev/null <<'EOF'
[Unit]
Description=Microproyecto NodeJS replica 2
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/opt/nodeapp
ExecStart=/usr/bin/node /opt/nodeapp/server.js
Restart=always
RestartSec=3
Environment=PORT=3001

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable nodeapp
sudo systemctl enable nodeapp2

sudo systemctl restart nodeapp
sudo systemctl restart nodeapp2

# --------------------------------------
# CONSUL CLIENT
# --------------------------------------

sudo tee /etc/consul.d/client.hcl >/dev/null <<EOF
datacenter = "dc1"
node_name  = "$HOSTNAME"

server = false

data_dir = "/opt/consul"

bind_addr   = "$IP"
client_addr = "0.0.0.0"

retry_join = ["192.168.100.10"]
EOF

# --------------------------------------
# SERVICIO NODE :3000
# --------------------------------------

sudo tee /etc/consul.d/nodeapp-3000.hcl >/dev/null <<EOF
service {
  name = "nodeapp"
  id   = "nodeapp-${HOSTNAME}-3000"

  address = "$IP"
  port    = 3000

  check {
    id       = "nodeapp-${HOSTNAME}-3000-health"
    name     = "NodeJS ${HOSTNAME}:3000 health"
    http     = "http://127.0.0.1:3000/health"
    interval = "10s"
    timeout  = "2s"
  }
}
EOF

# --------------------------------------
# SERVICIO NODE :3001
# --------------------------------------

sudo tee /etc/consul.d/nodeapp-3001.hcl >/dev/null <<EOF
service {
  name = "nodeapp"
  id   = "nodeapp-${HOSTNAME}-3001"

  address = "$IP"
  port    = 3001

  check {
    id       = "nodeapp-${HOSTNAME}-3001-health"
    name     = "NodeJS ${HOSTNAME}:3001 health"
    http     = "http://127.0.0.1:3001/health"
    interval = "10s"
    timeout  = "2s"
  }
}
EOF

sudo chown -R consul:consul /etc/consul.d

sudo consul validate /etc/consul.d

sudo systemctl enable consul
sudo systemctl restart consul

echo "======================================"
echo " $HOSTNAME configurado correctamente"
echo "======================================"