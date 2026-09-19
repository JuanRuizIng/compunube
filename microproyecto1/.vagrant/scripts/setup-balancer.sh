#!/bin/bash
# BALANCEADOR DE CARGA - HAProxy + Consul Client

# 1. Instalar dependencias, Consul y HAProxy
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -y && sudo apt-get install -y consul haproxy

# 2. Configurar y arrancar Consul Client
sudo mkdir -p /opt/consul
cat <<EOF | sudo tee /etc/consul.d/consul.hcl
datacenter  = "dc1"
data_dir    = "/opt/consul"
bind_addr   = "192.168.100.4"
client_addr = "0.0.0.0"
server      = false
retry_join  = ["192.168.100.3"]
EOF
sudo systemctl enable consul && sudo systemctl restart consul

# 3. Crear Página de Error 503 Personalizada
sudo mkdir -p /etc/haproxy/errors
cat <<EOF | sudo tee /etc/haproxy/errors/503.http
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>503 - Servicio No Disponible</title>
    <style>
        body { font-family: sans-serif; background: #0f172a; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
        .card { background: #1e293b; padding: 40px; border-radius: 12px; text-align: center; max-width: 450px; }
        h1 { color: #ef4444; font-size: 3rem; margin: 0; }
        p { color: #94a3b8; }
    </style>
</head>
<body>
    <div class="card">
        <h1>503</h1>
        <h2>Servicio No Disponible</h2>
        <p>Todos los servidores web estan fuera de linea o en mantenimiento.</p>
        <p>Por favor intente nuevamente mas tarde.</p>
    </div>
</body>
</html>
EOF

# 4. Configurar HAProxy con Service Discovery (SRV) y Estadísticas
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 503 /etc/haproxy/errors/503.http

resolvers consul
    nameserver consul 127.0.0.1:8600
    accepted_payload_size 8192
    hold valid 3s

listen haproxy_stats
    bind 0.0.0.0:1936
    mode http
    stats enable
    stats uri /

frontend http_front
    bind 0.0.0.0:80
    default_backend http_back

backend http_back
    balance roundrobin
    mode http
    server-template web 1-10 _mymicroservice._tcp.service.consul resolvers consul check init-addr none
EOF

sudo systemctl enable haproxy && sudo systemctl restart haproxy
