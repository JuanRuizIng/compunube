# Microproyecto 1 - Computación en la Nube

## Universidad Autónoma de Occidente

**Asignatura:** Computación en la Nube  
**Proyecto:** Microproyecto 1  
**Autor:** Kevin Muñoz  

---

# 1. Descripción

Este proyecto implementa una arquitectura distribuida y reproducible utilizando **Vagrant, VirtualBox, HashiCorp Consul, HAProxy, NodeJS y Artillery**.

El objetivo principal es implementar y demostrar conceptos relacionados con:

- Virtualización de infraestructura.
- Aprovisionamiento automático.
- Descubrimiento de servicios.
- Registro dinámico de servicios.
- Health Checks.
- Balanceo de carga.
- Escalabilidad horizontal.
- Alta disponibilidad.
- Tolerancia a fallos.
- Pruebas de carga.
- Infraestructura reproducible.

Toda la infraestructura puede ser creada automáticamente mediante:

```bash
vagrant up
```

Las máquinas virtuales pueden eliminarse completamente mediante:

```bash
vagrant destroy -f
```

y posteriormente reconstruirse utilizando nuevamente:

```bash
vagrant up
```

sin necesidad de configurar manualmente los servidores.

---



# 2. Arquitectura del sistema

La arquitectura implementada está compuesta por tres máquinas virtuales.

```text
                         HOST UBUNTU
                              |
              +---------------+---------------+
              |                               |
          Artillery                       Navegador
              |                               |
              +---------------+---------------+
                              |
                              v
                  +-----------------------+
                  |      LOADBALANCER     |
                  |    192.168.100.10     |
                  |                       |
                  | HAProxy               |
                  | Consul Server         |
                  | Consul DNS            |
                  +-----------+-----------+
                              |
                     Service Discovery
                         Consul DNS
                              |
                 +------------+------------+
                 |                         |
                 v                         v
        +------------------+       +------------------+
        |       WEB1       |       |       WEB2       |
        | 192.168.100.11   |       | 192.168.100.12   |
        |                  |       |                  |
        | Consul Client    |       | Consul Client    |
        | NodeJS :3000     |       | NodeJS :3000     |
        | NodeJS :3001     |       | NodeJS :3001     |
        +------------------+       +------------------+
```

El usuario realiza las solicitudes al balanceador:

```text
http://192.168.100.10
```

HAProxy consulta mediante DNS a Consul para conocer qué instancias del servicio `nodeapp` se encuentran disponibles.

Posteriormente distribuye las solicitudes entre las instancias saludables.

---



# 3. Tecnologías utilizadas

El proyecto utiliza las siguientes tecnologías:


| Tecnología         | Función                                                  |
| ------------------ | -------------------------------------------------------- |
| Vagrant            | Administración y aprovisionamiento de máquinas virtuales |
| VirtualBox         | Hipervisor                                               |
| Ubuntu Jammy 22.04 | Sistema operativo de las máquinas virtuales              |
| Consul             | Service Discovery y Health Checks                        |
| HAProxy            | Balanceador de carga                                     |
| NodeJS             | Runtime de la aplicación                                 |
| Express            | Servidor HTTP                                            |
| systemd            | Administración de servicios                              |
| Artillery          | Pruebas de carga                                         |
| Bash               | Automatización y provisioning                            |
| Git                | Control de versiones                                     |


---



# 4. Máquinas virtuales

La infraestructura utiliza tres máquinas virtuales.


| Máquina      | Dirección IP   | Función                 |
| ------------ | -------------- | ----------------------- |
| loadbalancer | 192.168.100.10 | Consul Server + HAProxy |
| web1         | 192.168.100.11 | Consul Client + NodeJS  |
| web2         | 192.168.100.12 | Consul Client + NodeJS  |


Todas las máquinas se encuentran conectadas mediante una red privada creada por Vagrant.

---



# 5. Estructura del proyecto

La estructura principal del repositorio es:

```text
Microproyecto1/
│
├── Vagrantfile
├── README.md
├── .gitignore
│
├── scripts/
│   ├── common.sh
│   ├── install-consul.sh
│   ├── configure-consul.sh
│   ├── provision-web.sh
│   └── provision-haproxy.sh
│
├── webapp/
│   ├── server.js
│   └── package.json
│
├── haproxy/
│   ├── haproxy.cfg
│   └── errors/
│       └── 503.http
│
├── artillery/
│   ├── basic.yml
│   ├── medium.yml
│   ├── high.yml
│   └── stress.yml
│
└── docs/
    ├── artillery-basic.txt
    ├── artillery-medium.txt
    ├── artillery-high.txt
    ├── artillery-stress.txt
    ├── medium-2-instancias.txt
    └── medium-4-instancias.txt
```

---



# 6. Vagrant

Vagrant es utilizado para crear y administrar automáticamente las máquinas virtuales.

La infraestructura puede iniciarse mediante:

```bash
vagrant up
```

Vagrant crea:

```text
loadbalancer
web1
web2
```

Cada máquina recibe automáticamente:

- Hostname.
- Dirección IP.
- Memoria RAM.
- CPU.
- Red privada.
- Scripts de provisioning.

Para consultar el estado:

```bash
vagrant status
```

Resultado esperado:

```text
loadbalancer   running
web1           running
web2           running
```

---



# 7. Aprovisionamiento automático

Uno de los objetivos principales del proyecto es evitar la configuración manual de las máquinas virtuales.

Para ello se utilizan scripts Bash ejecutados automáticamente por Vagrant.

Los scripts principales son:

```text
scripts/
├── common.sh
├── install-consul.sh
├── configure-consul.sh
├── provision-web.sh
└── provision-haproxy.sh
```



## [common.sh](http://common.sh)

Contiene funciones y dependencias comunes utilizadas por los demás scripts.

Entre ellas:

- actualización de repositorios;
- instalación de `curl`;
- instalación de `wget`;
- instalación de `gpg`;
- instalación de `dnsutils`;
- certificados;
- utilidades necesarias para el proyecto.

---



## [install-consul.sh](http://install-consul.sh)

Se encarga de:

- agregar el repositorio de HashiCorp;
- instalar Consul;
- crear los directorios de configuración;
- configurar permisos;
- configurar el servicio systemd;
- verificar la instalación.

---



## [configure-consul.sh](http://configure-consul.sh)

Configura automáticamente Consul dependiendo del hostname.

Si la máquina es:

```text
loadbalancer
```

se configura como:

```text
Consul Server
```

Si la máquina es:

```text
web1
web2
```

se configura como:

```text
Consul Client
```

---



## [provision-web.sh](http://provision-web.sh)

Se encarga de configurar los servidores web.

Realiza automáticamente:

- instalación de NodeJS;
- instalación de dependencias NPM;
- copia de la aplicación;
- creación de servicios systemd;
- creación de las instancias NodeJS;
- registro de servicios en Consul;
- configuración de Health Checks.

---



## [provision-haproxy.sh](http://provision-haproxy.sh)

Se encarga de:

- instalar HAProxy;
- copiar la configuración;
- configurar los resolvers de Consul;
- configurar estadísticas;
- instalar la página personalizada HTTP 503;
- validar la configuración;
- iniciar HAProxy.

---



# 8. Aplicación NodeJS

Los servidores `web1` y `web2` ejecutan una aplicación desarrollada con NodeJS y Express.

Cada servidor ejecuta dos instancias.

## WEB1

```text
192.168.100.11:3000
192.168.100.11:3001
```



## WEB2

```text
192.168.100.12:3000
192.168.100.12:3001
```

Esto permite disponer de cuatro réplicas del mismo servicio.

---



# 9. Endpoints

La aplicación dispone de diferentes endpoints.

## Endpoint principal

```text
/
```

Devuelve información acerca del servidor que respondió.

Ejemplo:

```json
{
    "status": "ok",
    "server": "web1",
    "hostname": "web1",
    "port": "3000",
    "timestamp": "2026-09-05T07:54:15.416Z"
}
```

Esto permite observar fácilmente qué servidor recibió cada solicitud.

---



## Health Check

```text
/health
```

Ejemplo:

```json
{
    "status": "healthy",
    "server": "web1",
    "port": "3000"
}
```

Este endpoint es utilizado por Consul y HAProxy para determinar si una instancia se encuentra saludable.

---



## Información

```text
/api/info
```

Entrega información adicional de la instancia.

---



# 10. Servicios systemd

Las aplicaciones NodeJS se ejecutan como servicios de Linux.

Los servicios utilizados son:

```text
nodeapp.service
nodeapp2.service
```

Para comprobarlos:

```bash
sudo systemctl status nodeapp
```

y:

```bash
sudo systemctl status nodeapp2
```

También puede utilizarse:

```bash
systemctl is-active nodeapp
systemctl is-active nodeapp2
```

Resultado esperado:

```text
active
active
```

---



# 11. Consul

HashiCorp Consul se utiliza como sistema de **Service Discovery**.

El servidor Consul se encuentra en:

```text
192.168.100.10
```

Los clientes son:

```text
web1
web2
```

---



# 12. Clúster Consul

Para verificar los miembros del clúster:

```bash
vagrant ssh loadbalancer -c "consul members"
```

Se deben observar:

```text
loadbalancer
web1
web2
```

con estado:

```text
alive
```

---



# 13. Consul Server

El nodo:

```text
loadbalancer
```

funciona como Consul Server.

Su dirección es:

```text
192.168.100.10
```

El servidor administra:

- catálogo de servicios;
- Health Checks;
- DNS;
- información del clúster;
- registro de nodos.

---



# 14. Consul Clients

Los servidores:

```text
web1
web2
```

funcionan como Consul Clients.

Estos clientes registran las instancias NodeJS y envían información de estado al servidor Consul.

---



# 15. Registro de servicios

Las cuatro instancias son registradas utilizando el mismo nombre:

```text
nodeapp
```

pero cada instancia posee un identificador diferente.

Ejemplo conceptual:

```text
nodeapp-web1-3000
nodeapp-web1-3001
nodeapp-web2-3000
nodeapp-web2-3001
```

Esto permite que Consul trate todas las instancias como réplicas del mismo servicio.

---



# 16. Health Checks

Cada instancia posee un Health Check HTTP.

Ejemplo:

```text
http://127.0.0.1:3000/health
```

y:

```text
http://127.0.0.1:3001/health
```

Consul ejecuta periódicamente estas solicitudes.

Si recibe:

```text
HTTP 200
```

la instancia se considera:

```text
passing
```

Si deja de responder correctamente, Consul cambia su estado y HAProxy puede dejar de utilizarla.

---



# 17. Interfaz web de Consul

La interfaz gráfica puede consultarse desde el HOST utilizando:

```text
http://192.168.100.10:8500
```

Desde esta interfaz pueden observarse:

- nodos;
- servicios;
- Health Checks;
- estado de las instancias;
- información del clúster.

---



# 18. DNS de Consul

Consul proporciona un servidor DNS en el puerto:

```text
8600
```

HAProxy utiliza este DNS para descubrir dinámicamente las instancias.

Una consulta puede realizarse con:

```bash
dig @192.168.100.10 -p 8600 SRV _nodeapp._tcp.service.consul
```

También desde el balanceador:

```bash
dig @127.0.0.1 -p 8600 SRV _nodeapp._tcp.service.consul
```

El resultado debe incluir las instancias disponibles y sus respectivos puertos.

---



# 19. HAProxy

HAProxy funciona como balanceador de carga.

Se encuentra instalado en:

```text
loadbalancer
```

y escucha solicitudes HTTP en:

```text
192.168.100.10:80
```

Por lo tanto, el acceso principal al sistema es:

```text
http://192.168.100.10
```

---



# 20. Balanceo Round Robin

El algoritmo utilizado es:

```text
roundrobin
```

Esto permite distribuir las solicitudes entre las instancias disponibles.

Por ejemplo:

```text
Solicitud 1 → web1:3000
Solicitud 2 → web1:3001
Solicitud 3 → web2:3000
Solicitud 4 → web2:3001
Solicitud 5 → web1:3000
...
```

El orden exacto puede variar según el estado y descubrimiento de los backends.

---



# 21. Integración Consul + HAProxy

HAProxy no depende de una lista estática de servidores.

Utiliza Consul DNS para descubrir dinámicamente las instancias de:

```text
nodeapp
```

La consulta utilizada es:

```text
_nodeapp._tcp.service.consul
```

Consul responde con:

- dirección del servicio;
- puerto;
- disponibilidad.

HAProxy utiliza esta información para construir dinámicamente su grupo de backends.

El flujo es:

```text
Cliente
   |
   v
HAProxy
   |
   v
Consul DNS
   |
   v
Service Discovery
   |
   +-------------------------------+
   |              |                |
   v              v                v
web1:3000     web1:3001       web2:3000 ...
```

---



# 22. Estadísticas de HAProxy

HAProxy proporciona una interfaz de estadísticas.

Disponible en:

```text
http://192.168.100.10:8404/stats
```

Desde esta interfaz pueden observarse métricas como:

- sesiones;
- solicitudes;
- servidores activos;
- servidores caídos;
- errores;
- tiempo de respuesta;
- estado de los backends.

---



# 23. Escalabilidad horizontal

Una de las pruebas realizadas consiste en aumentar el número de instancias del servicio.

## Escenario inicial

Dos instancias:

```text
web1:3000
web2:3000
```



## Escenario escalado

Cuatro instancias:

```text
web1:3000
web1:3001
web2:3000
web2:3001
```

Las nuevas instancias son registradas en Consul.

HAProxy puede descubrirlas mediante DNS sin necesidad de mantener una lista manual de direcciones y puertos.

---



# 24. Prueba de balanceo

El balanceo puede comprobarse ejecutando:

```bash
for i in {1..20}; do
    curl -s http://192.168.100.10
    echo
done
```

Las respuestas deben provenir de diferentes instancias.

Ejemplo:

```text
web1
web2
web1
web2
...
```

Con cuatro réplicas también pueden observarse diferentes puertos:

```text
3000
3001
```

---



# 25. Alta disponibilidad

La arquitectura permite que el sistema continúe funcionando si una instancia deja de responder.

Por ejemplo, se puede detener una réplica:

```bash
vagrant ssh web1 -c "sudo systemctl stop nodeapp2"
```

Después de que los Health Checks detecten el cambio, la instancia deja de recibir tráfico.

El sistema continúa utilizando las demás instancias disponibles.

---



# 26. Recuperación automática

La instancia puede volver a iniciarse mediante:

```bash
vagrant ssh web1 -c "sudo systemctl start nodeapp2"
```

Después de que el Health Check vuelva a indicar:

```text
passing
```

la instancia vuelve a estar disponible para el balanceador.

Esto demuestra la capacidad de recuperación dinámica del sistema.

---



# 27. Caída completa de backends

También se realizó una prueba donde todas las instancias NodeJS se encuentran fuera de servicio.

En este escenario HAProxy no dispone de ningún backend saludable.

El sistema responde con:

```text
HTTP 503 Service Unavailable
```

---



# 28. Página HTTP 503 personalizada

Se configuró una página personalizada para el error:

```text
503 Service Unavailable
```

Esta página se encuentra en:

```text
haproxy/errors/503.http
```

y es utilizada cuando ninguna instancia del servicio se encuentra disponible.

---



# 29. Artillery

Artillery es utilizado para realizar pruebas de carga contra HAProxy.

Las pruebas **no se realizan directamente contra** `web1` **o** `web2`.

El objetivo de las pruebas es:

```text
http://192.168.100.10
```

De esta manera todo el tráfico atraviesa HAProxy.

---



# 30. Escenarios de Artillery

Se crearon diferentes escenarios.

```text
artillery/
├── basic.yml
├── medium.yml
├── high.yml
└── stress.yml
```

---



# 31. Prueba básica

La prueba básica utiliza aproximadamente:

```text
2 solicitudes/segundo
```

durante:

```text
30 segundos
```

Número aproximado:

```text
60 solicitudes
```

Para ejecutarla:

```bash
artillery run artillery/basic.yml
```

---



# 32. Prueba media

La prueba media utiliza:

```text
10 solicitudes/segundo
```

durante:

```text
60 segundos
```

Número aproximado:

```text
600 solicitudes
```

Ejecución:

```bash
artillery run artillery/medium.yml
```

---



# 33. Prueba alta

La prueba alta utiliza:

```text
30 solicitudes/segundo
```

durante:

```text
60 segundos
```

Número aproximado:

```text
1800 solicitudes
```

Ejecución:

```bash
artillery run artillery/high.yml
```

---



# 34. Prueba progresiva

La prueba `stress.yml` incrementa progresivamente la carga.

```text
0 - 30 s       →  2 req/s
30 - 60 s      → 10 req/s
60 - 90 s      → 20 req/s
90 - 120 s     → 30 req/s
```

Para ejecutarla:

```bash
artillery run artillery/stress.yml
```

---



# 35. Métricas analizadas

Durante las pruebas se analizaron principalmente:

```text
http.requests
http.request_rate
http.response_time.mean
http.response_time.p95
http.response_time.p99
vusers.completed
vusers.failed
```

Estas métricas permiten analizar:

- cantidad de solicitudes;
- velocidad de solicitudes;
- latencia promedio;
- percentiles de latencia;
- usuarios completados;
- errores.

---



# 36. Resultado de la prueba básica

En la prueba básica se obtuvieron:


| Métrica           | Resultado |
| ----------------- | --------- |
| Solicitudes       | 60        |
| HTTP 200          | 60        |
| Request rate      | 2/s       |
| Errores           | 0         |
| Latencia mínima   | 1 ms      |
| Latencia promedio | 2.2 ms    |
| Latencia máxima   | 4 ms      |
| Mediana           | 2 ms      |
| p95               | 3 ms      |
| p99               | 4 ms      |


El sistema atendió el 100 % de las solicitudes sin errores.

---



# 37. Comparación de escalabilidad

También se realizaron pruebas utilizando la misma carga con diferentes cantidades de instancias.

## Escenario A

```text
2 instancias
```



## Escenario B

```text
4 instancias
```

Esto permite comparar:


| Métrica        | 2 instancias           | 4 instancias           |
| -------------- | ---------------------- | ---------------------- |
| Solicitudes    | Resultado experimental | Resultado experimental |
| Request rate   | Resultado experimental | Resultado experimental |
| Latencia media | Resultado experimental | Resultado experimental |
| p95            | Resultado experimental | Resultado experimental |
| p99            | Resultado experimental | Resultado experimental |
| Errores        | Resultado experimental | Resultado experimental |


Los resultados completos de las pruebas se almacenan en el directorio:

```text
docs/
```

---



# 38. Interpretación de escalabilidad

El aumento del número de instancias no necesariamente produce una reducción significativa de latencia cuando la carga aplicada es baja respecto a la capacidad total de los servidores.

Sin embargo, disponer de varias instancias permite:

- distribuir la carga;
- aumentar la capacidad disponible;
- reducir la dependencia de una sola instancia;
- mejorar la tolerancia a fallos;
- permitir escalamiento horizontal.

---



# 39. Prueba de reconstrucción completa

Para comprobar que la infraestructura es reproducible se eliminaron completamente las máquinas virtuales.

```bash
vagrant destroy -f
```

Posteriormente se reconstruyó toda la infraestructura mediante:

```bash
vagrant up
```

Vagrant ejecutó automáticamente los scripts de aprovisionamiento.

Esto permitió reconstruir:

```text
loadbalancer
├── Consul Server
└── HAProxy

web1
├── Consul Client
├── NodeJS :3000
└── NodeJS :3001

web2
├── Consul Client
├── NodeJS :3000
└── NodeJS :3001
```

sin realizar configuraciones manuales dentro de las máquinas virtuales.

---



# 40. Cómo ejecutar el proyecto

## Requisitos

El equipo HOST debe disponer de:

- Git
- Vagrant
- VirtualBox

Artillery es necesario únicamente para ejecutar las pruebas de carga.

---



## Clonar repositorio

```bash
git clone https://github.com/KevinMG1601/nube-microproyecto-1.git
```

```bash
cd Microproyecto1
```

---



## Crear infraestructura

```bash
vagrant up
```

---



## Consultar estado

```bash
vagrant status
```

---



# 41. Verificación de Consul

```bash
vagrant ssh loadbalancer -c "consul members"
```

También puede verificarse el líder:

```bash
curl -s http://192.168.100.10:8500/v1/status/leader
```

---



# 42. Verificación de NodeJS

```bash
curl http://192.168.100.11:3000/health
curl http://192.168.100.11:3001/health

curl http://192.168.100.12:3000/health
curl http://192.168.100.12:3001/health
```

Las cuatro solicitudes deben indicar:

```text
healthy
```

---



# 43. Verificación de HAProxy

Validar servicio:

```bash
vagrant ssh loadbalancer -c "systemctl is-active haproxy"
```

Validar configuración:

```bash
vagrant ssh loadbalancer -c \
"sudo haproxy -c -f /etc/haproxy/haproxy.cfg"
```

Resultado esperado:

```text
Configuration file is valid
```

---



# 44. Verificación de Service Discovery

Consultar DNS SRV:

```bash
vagrant ssh loadbalancer -c \
'dig @127.0.0.1 -p 8600 SRV _nodeapp._tcp.service.consul +short'
```

Deben aparecer las instancias registradas.

---



# 45. Verificación del balanceador

Ejecutar:

```bash
for i in {1..12}; do
    curl -s http://192.168.100.10
    echo
done
```

Las respuestas deben ser distribuidas entre diferentes instancias.

---



# 46. Interfaces web



## Consul

```text
http://192.168.100.10:8500
```



## HAProxy Stats

```text
http://192.168.100.10:8404/stats
```

---



# 47. Detener infraestructura

Para apagar las máquinas sin eliminarlas:

```bash
vagrant halt
```

Para volver a iniciarlas:

```bash
vagrant up
```

---



# 48. Destruir infraestructura

Para eliminar completamente las máquinas:

```bash
vagrant destroy -f
```

Posteriormente pueden reconstruirse con:

```bash
vagrant up
```

---



# 49. Comandos útiles



## Estado de Vagrant

```bash
vagrant status
```



## Entrar al balanceador

```bash
vagrant ssh loadbalancer
```



## Entrar a WEB1

```bash
vagrant ssh web1
```



## Entrar a WEB2

```bash
vagrant ssh web2
```



## Miembros de Consul

```bash
consul members
```



## Servicios registrados

```bash
consul catalog services
```



## Estado de HAProxy

```bash
sudo systemctl status haproxy
```



## Estado de Consul

```bash
sudo systemctl status consul
```



## Estado NodeJS

```bash
sudo systemctl status nodeapp
sudo systemctl status nodeapp2
```

---



# 50. Flujo general del sistema

El funcionamiento completo puede resumirse de la siguiente manera:

```text
                  CLIENTE
                     |
                     |
                     v
               HAProxy :80
                     |
                     |
              Consulta Consul
                     |
                     v
               Consul DNS
                  :8600
                     |
              Service Discovery
                     |
       +-------------+-------------+
       |             |             |
       v             v             v
   web1:3000     web1:3001     web2:3000
                                    |
                                    v
                                web2:3001
```

Los Health Checks determinan qué instancias pueden recibir tráfico.

---



# 51. Resultados generales

Las pruebas realizadas permitieron comprobar que:

1. Vagrant crea correctamente las tres máquinas virtuales.
2. El aprovisionamiento instala automáticamente las dependencias.
3. Consul forma correctamente el clúster.
4. Los servidores web se registran automáticamente.
5. Los Health Checks identifican el estado de las instancias.
6. HAProxy descubre dinámicamente los servicios mediante Consul DNS.
7. HAProxy distribuye las solicitudes utilizando Round Robin.
8. Es posible aumentar el número de réplicas.
9. Una instancia puede fallar sin detener completamente el servicio.
10. Una instancia recuperada puede volver a recibir tráfico.
11. Cuando no existen backends disponibles se devuelve HTTP 503.
12. Artillery permite evaluar el comportamiento bajo diferentes niveles de carga.
13. La infraestructura puede destruirse y reconstruirse automáticamente.

---



# 52. Conclusiones

La implementación permitió desarrollar una infraestructura distribuida utilizando herramientas comunes en entornos de computación en la nube.

Vagrant permitió definir y reproducir la infraestructura de manera automatizada, reduciendo la necesidad de configuraciones manuales dentro de cada máquina virtual.

HashiCorp Consul permitió implementar descubrimiento de servicios y Health Checks. Gracias a esto, las instancias NodeJS pueden registrarse bajo un mismo servicio y su disponibilidad puede ser consultada dinámicamente.

La integración entre Consul y HAProxy permitió evitar una configuración completamente estática de los backends. HAProxy puede utilizar la información proporcionada mediante DNS SRV para conocer las instancias disponibles del servicio.

El uso de múltiples instancias permitió demostrar conceptos de escalabilidad horizontal y tolerancia a fallos. Cuando una instancia deja de estar disponible, las demás pueden continuar atendiendo solicitudes.

Las pruebas realizadas con Artillery permitieron observar el comportamiento de la infraestructura ante diferentes niveles de tráfico y analizar métricas relacionadas con solicitudes, errores y tiempos de respuesta.

Finalmente, la prueba de destrucción y reconstrucción completa permitió verificar que la infraestructura puede ser reproducida mediante `vagrant up`, demostrando la utilidad del aprovisionamiento automático y de la infraestructura definida mediante código.

---



# 53. Autor


|                                                                                                                         |                                                                                                                                                                                                                                             |
| ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Kevin Muñoz](https://avatars.githubusercontent.com/u/143461336?v=4) **[Kevin Muñoz](https://github.com/KevinMG1601)** | Created by **Kevin Muñoz**. I would like to know your opinion about this project. You can write me by [email](mailto:kevin.andres2636@gmail.com) or connect with me on [LinkedIn](https://www.linkedin.com/in/kevin-mu%C3%B1oz-231b80303/). |


