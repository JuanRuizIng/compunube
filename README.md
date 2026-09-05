# Microproyecto 1: Cluster Consul + HAProxy + NodeJS + Artillery
**Computación en la Nube - Maestría / Especialización en IA - UAO**

Infraestructura automatizada de alta disponibilidad con **HashiCorp Consul** para Service Discovery y Health Checking, **HAProxy** como balanceador de carga elástico con GUI de estadísticas y página 503 personalizada, microservicios web en **NodeJS** con soporte de réplicas en caliente y pruebas de carga con **Artillery**.

---

## 1. Topología del Clúster y Direccionamiento

| Máquina Virtual | IP Privada | Rol en la Arquitectura | Rol en Consul | Puertos Clave |
| :--- | :--- | :--- | :--- | :--- |
| **`servidorUbuntu`** | `192.168.100.3` | Servidor Web 1 (NodeJS) | **Consul Server** (Líder del clúster + UI) | `8500` (Consul Web UI), `8600` (Consul DNS), `3000` (App) |
| **`clienteUbuntu`** | `192.168.100.2` | Servidor Web 2 (NodeJS) | **Consul Client** (Agente) | `3000` (App), `8301` (Serf LAN) |
| **`balancer`** | `192.168.100.4` | Balanceador de Carga | **Consul Client** (Agente) | `80` (HTTP Web), `1936` (HAProxy Stats GUI) |

---

## 2. Puesta en Marcha (Aprovisionamiento Automatizado)

Para encender y aprovisionar las 3 máquinas virtuales desde cero:

```powershell
vagrant up
```

Para reaplicar los scripts en máquinas que ya se encuentran encendidas:
```powershell
vagrant provision
```

> **Nota:** Los scripts de aprovisionamiento (`scripts/setup-*.sh`) instalan todas las dependencias (Node.js 20, Git, Consul, HAProxy), configuran la red y preparan el repositorio de la aplicación. Los microservicios quedan listos para ser iniciados a demanda para la sustentación.

---

## 3. URLs de Verificación y Monitoreo

* 🌐 **Aplicación Web Balanceada:** `http://192.168.100.4` (Distribuye peticiones entre las instancias activas).
* 📊 **HAProxy Stats GUI:** `http://192.168.100.4:1936` (Panel interactivo con métricas, latencias, estado `UP`/`DOWN` y contadores de tráfico).
* 🔴 **Consul Web UI:** `http://192.168.100.3:8500` (Catálogo de nodos, servicios registrados y chequeos de salud `/health`).

---

## 4. Guía Paso a Paso para la Sustentación Oral

### Paso 1: Iniciar las instancias de los Microservicios
Abre dos terminales de PowerShell en tu equipo:

* **En la Terminal 1 (Servidor 1):**
  ```powershell
  vagrant ssh servidorUbuntu
  cd ~/consulService/app
  node index.js 3000
  ```
* **En la Terminal 2 (Servidor 2):**
  ```powershell
  vagrant ssh clienteUbuntu
  cd ~/consulService/app
  node index.js 3000
  ```

---

### Paso 2: Demostrar el Balanceo de Carga (Round-Robin)
1. Abre tu navegador en 👉 `http://192.168.100.4` y refresca la página (F5).
2. Observa cómo el campo `"data_host"` en la respuesta JSON se alterna entre:
   * `"192.168.100.3"`
   * `"192.168.100.2"`
3. Abre el panel de HAProxy en 👉 `http://192.168.100.4:1936`:
   * Observa `web1` y `web2` en **color VERDE (`UP`)** y cómo los contadores de peticiones suben equitativamente (50% / 50%).

---

### Paso 3: Demostrar Tolerancia a Fallos (Resiliencia)
1. En la Terminal 2 (`clienteUbuntu`), presiona `Ctrl + C` para detener el microservicio.
2. Observa en **Consul UI** (`:8500`) cómo el health check `/health` pasa a fallo y en **HAProxy** (`:1936`) la ranura pasa a **ROJO (`DOWN`)**.
3. Refresca `http://192.168.100.4`: **El servicio no se interrumpe**, HAProxy redirige el 100% de las peticiones a `servidorUbuntu`.

---

### Paso 4: Demostrar la Página de Error 503 Personalizada
1. En la Terminal 1 (`servidorUbuntu`), presiona `Ctrl + C` para detener el último microservicio activo.
2. Refresca `http://192.168.100.4`:
   * Se desplegará la **página personalizada de error 503** estilizada indicando que el servicio no está disponible temporalmente.
3. Vuelve a ejecutar `node index.js 3000` en cualquiera de las dos máquinas:
   * En ~3 segundos el sistema se autorecupera y la página web vuelve a responder normalmente sin reiniciar HAProxy.

---

### Paso 5: Demostrar Escalabilidad Elástica (Réplicas en Caliente)
1. En cualquier máquina (`servidorUbuntu` o `clienteUbuntu`), abre una nueva terminal y levanta una segunda instancia en otro puerto:
   ```bash
   PORT=3001 node index.js 3001
   ```
2. Revisa el panel de **HAProxy** (`:1936`):
   * Gracias a la consulta DNS de registros **SRV** (`_mymicroservice._tcp.service.consul`), HAProxy descubre automáticamente la IP y el nuevo puerto `3001` y comienza a balancear tráfico hacia ella inmediatamente sin modificar `haproxy.cfg`.

---

### Paso 6: Pruebas de Carga con Artillery
Desde `servidorUbuntu` o `clienteUbuntu`:

```bash
# 1. Ejecutar la prueba de estrés multinivel
npx -y artillery run /vagrant/artillery-load-test.yml --output /vagrant/report.json


---

## 5. Comandos Útiles de Mantenimiento

* **Reiniciar / Limpiar la GUI de HAProxy:**
  Para reiniciar los contadores a cero y remover ranuras inactivas en `http://192.168.100.4:1936`:
  ```powershell
  vagrant ssh balancer -c "sudo systemctl restart haproxy"
  ```
* **Ver estado del Clúster Consul:**
  ```powershell
  vagrant ssh servidorUbuntu -c "consul members"
  ```
* **Consultar los registros SRV de Consul por DNS:**
  ```powershell
  vagrant ssh balancer -c "dig @127.0.0.1 -p 8600 _mymicroservice._tcp.service.consul SRV"
  ```


