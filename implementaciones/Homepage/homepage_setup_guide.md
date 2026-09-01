# Guía Definitiva de Implementación de Homepage

Esta guía detalla el paso a paso de todas las configuraciones que realizamos para levantar y personalizar tu panel de **Homepage**, dejándolo optimizado con widgets y servicios como Proxmox, Cloudflare y Dockhand.

---

## 1. Instalación Base con Docker Compose

El primer paso para implementar Homepage es levantar el contenedor usando Docker. Es vital asegurarse de pasar el "socket" de Docker para que Homepage pueda monitorear otros contenedores si se requiere en el futuro.

1. **Crear el directorio y archivo:**
   ```bash
   mkdir -p ~/homepage
   cd ~/homepage
   nano docker-compose.yml
   ```

2. **Configuración de `docker-compose.yml`:**
   ```yaml
   version: '3.3'
   services:
     homepage:
       image: ghcr.io/gethomepage/homepage:latest
       container_name: homepage
       ports:
         - 3000:3000
       volumes:
         - ./config:/app/config # Carpeta donde vivirán nuestros .yaml
         - /var/run/docker.sock:/var/run/docker.sock:ro # Permite a Homepage leer el estado de Docker
       restart: unless-stopped
   ```

3. **Levantar el contenedor:**
   ```bash
   docker compose up -d
   ```
   *Una vez levantado, Homepage crea automáticamente los archivos de configuración base (`services.yaml`, `widgets.yaml`, etc.) dentro de la carpeta `~/homepage/config`.*

---

## 2. Widgets Globales y de Información (`widgets.yaml`)

El archivo `widgets.yaml` controla los elementos que aparecen en la parte superior de tu panel (reloj, clima, uso de CPU del nodo principal, etc.).

**Ruta:** `~/homepage/config/widgets.yaml`

```yaml
- search:
    provider: google
    target: _blank

- datetime:
    text_size: xl
    format:
      timeStyle: short
      dateStyle: short

- openmeteo:
    label: Quilpué
    latitude: -33.0458
    longitude: -71.4422
    timezone: America/Santiago
    units: metric

- resources:
    cpu: true
    memory: true
    disk: /
```

---

## 3. Servicios y Widgets Integrados (`services.yaml`)

El corazón de Homepage. Aquí agrupamos tus servicios por categorías y agregamos widgets inteligentes a las tarjetas para ver datos en tiempo real.

**Ruta:** `~/homepage/config/services.yaml`

> [!IMPORTANT]  
> En este archivo la autenticación de Proxmox usa las palabras `username` y `password`.

```yaml
---
- Docker Management:
    - Dockhand:
        icon: dockhand.png
        href: http://TU_IP:3000
        description: Administrador de Contenedores
        widget:
          type: dockhand
          url: http://TU_IP:3000
          username: tu_usuario
          password: tu_password

- Redes y Túneles:
    - Cloudflare:
        icon: cloudflare.png
        href: https://one.dash.cloudflare.com/
        description: Zero Trust Tunnels
        widget:
          type: cloudflared
          accountid: TU_ACCOUNT_ID # Obtenido de la URL del panel de Cloudflare
          tunnelid: TU_TUNNEL_ID   # Obtenido desde la sección Tunnels
          key: TU_API_TOKEN        # Generado en "My Profile" > "API Tokens"

- Virtualización:
    - Proxmox VE:
        icon: proxmox.png
        href: https://TU_IP_PROXMOX:8006
        description: Hypervisor Cluster
        widget:
          type: proxmox
          url: https://TU_IP_PROXMOX:8006
          username: root@pam!Homepage  # Nombre de usuario EXACTO del token
          password: TU_SECRET_TOKEN
```

> [!TIP]
> **Creación del Token de Proxmox:** 
> 1. Ve a **Datacenter > Permissions > API Tokens** en Proxmox.
> 2. Selecciona tu usuario (`root@pam`).
> 3. En Token ID escribe `Homepage` (Respeta mayúsculas/minúsculas).
> 4. **CRÍTICO:** Quita la selección de la casilla *"Privilege Separation"* para que el token herede tus permisos de administrador y pueda ver todo.
> 5. Guarda el `Secret` porque Proxmox solo lo muestra una vez.

---

## 4. Widgets para Máquinas Virtuales Individuales

Si deseas tener una tarjeta dedicada a una VM específica y ver su uso de CPU/RAM, se requieren **dos archivos**:

### A. Archivo Estructural (`proxmox.yaml`)
Este archivo le enseña a Homepage cómo conectarse al servidor para extraer métricas individuales. 

**Ruta:** `~/homepage/config/proxmox.yaml`

> [!WARNING]  
> A diferencia de `services.yaml`, este archivo **exige** que las credenciales se llamen `token` y `secret`.

```yaml
pve: # 'pve' es el alias de conexión que usaremos luego
  url: https://TU_IP_PROXMOX:8006
  token: root@pam!Homepage
  secret: TU_SECRET_TOKEN
```

### B. Agregar la Máquina al Dashboard (`services.yaml`)
Con la conexión establecida, se agrega la VM al archivo de servicios, referenciando el nodo real y el ID de la VM.

```yaml
    - Mi Maquina Virtual 1:
        icon: ubuntu.png
        href: http://IP_DE_LA_MAQUINA:80 # Al hacer clic en la tarjeta te lleva aquí
        description: Servidor Web
        proxmoxNode: proxtux     # El nombre EXACTO de tu nodo en Proxmox (No confundir con el alias de conexión)
        proxmoxVMID: 102         # El ID numérico de tu VM
        proxmoxType: qemu        # Usar 'qemu' para VMs y 'lxc' para contenedores
```

---

## 5. Aplicando los Cambios

> [!CAUTION]
> **La regla de oro de Homepage:**
> Los cambios visuales en `services.yaml` o `widgets.yaml` se actualizan solos al instante al guardar el archivo. Sin embargo, cuando modificas archivos estructurales y de conexión como `proxmox.yaml` o `docker.yaml`, **debes reiniciar el contenedor obligatoriamente** para que Homepage recargue las credenciales y certificados internos.

**Comando de reinicio:**
```bash
docker restart homepage
```
