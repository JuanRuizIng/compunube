#!/bin/bash

echo "Instalando Consul y HAProxy..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install consul haproxy -y

echo "Configurando Consul (Servidor)..."
mkdir -p /etc/consul.d
cat <<EOF > /etc/consul.d/server.json
{
  "server": true,
  "bootstrap_expect": 1,
  "ui_config": {"enabled": true},
  "client_addr": "0.0.0.0",
  "bind_addr": "192.168.100.2",
  "data_dir": "/var/lib/consul"
}
EOF
nohup consul agent -config-dir=/etc/consul.d > /var/log/consul.log 2>&1 &

echo "Creando página de error personalizada 503..."
mkdir -p /etc/haproxy/errors
cat <<EOF > /etc/haproxy/errors/503_custom.http
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html>
  <head><title>Sitio en Mantenimiento</title></head>
  <body style="text-align: center; padding: 50px; font-family: Arial;">
    <h1>Lo sentimos!</h1>
    <p>En este momento ningun servidor web esta disponible. Estamos trabajando para solucionarlo.</p>
  </body>
</html>
EOF

echo "Configurando HAProxy..."
cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    user haproxy
    group haproxy

defaults
    log global
    mode http
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 503 /etc/haproxy/errors/503_custom.http

# Integración DNS con Consul (Puerto 8600)
resolvers consul
    nameserver consul1 127.0.0.1:8600
    accepted_payload_size 8192
    hold valid 5s

frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 5s

frontend http_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    # Descubrimiento dinámico buscando 'mymicroservice' en Consul
    server-template web 4 mymicroservice.service.consul resolvers consul resolve-prefer ipv4 check
EOF

systemctl restart haproxy