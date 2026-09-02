# 🏠 Guía Completa: Despliegue de Home Assistant OS (HAOS) en Proxmox VE para HomeLab

Esta guía documenta la instalación, configuración e integración completa de **Home Assistant OS (HAOS)** sobre la infraestructura de virtualización de **Proxmox VE**, lista para su publicación en **mi-homelab.cl**.

---

## 📌 1. Introducción y Arquitectura del Proyecto

En el ecosistema domótico moderno, **Home Assistant** es el estándar de oro para centralizar dispositivos inteligentes (luces, switches, sensores Zigbee, cámaras, termostatos y paneles de energía).

### ¿Por qué elegir Home Assistant OS (HAOS) en Proxmox VE?

Al evaluar las opciones de despliegue en un HomeLab existen dos alternativas principales:

1. **Home Assistant en Docker Container:** Muy ligero, pero **carece del Supervisor interno** y de la tienda integrada de Add-ons (lo que exige gestionar contenedores auxiliares manualmente).
2. **Home Assistant OS (HAOS) en Máquina Virtual Proxmox VE (Elección Seleccionada):**
   * **Supervisor Completo:** Tienda oficial e instalador de Add-ons con 1 solo clic (Mosquitto MQTT, Zigbee2MQTT, Node-RED, ESPHome, NGINX Home Assistant SSL, etc.).
   * **Actualizaciones Integrales:** El sistema operativo, el core de domótica y todas sus extensiones se actualizan con un solo botón sin romper dependencias.
   * **Aislamiento e Integridad:** Vive en su propia máquina virtual aislada con virtualización por hardware (UEFI / Q35).
   * **Respaldos Automatizados en Proxmox:** Snapshots instantáneos antes de cambios importantes.

---

## 🛠️ 2. Ficha Técnica del Servidor y VM

* **Servidor Hypervisor:** Proxmox VE (`proxtux` - `<IP_PROXMOX1>`)
* **ID de la VM:** `104`
* **Nombre de la VM:** `HomeAssistant`
* **Arquitectura de VM:** Q35 + BIOS UEFI (OVMF) (SecureBoot desactivado: `pre-enrolled-keys=0`)
* **Recursos Asignados:**
  * **vCPU:** 2 Cores (Host CPU Passthrough)
  * **RAM:** 4096 MB (4 GB)
  * **Almacenamiento:** 32 GB LVM en Almacenamiento NAS (`LUN-OMV-2TB`)
  * **Red:** Bridge `vmbr0` (VirtIO)
* **Puerto Web Inicial:** `8123` (`http://<IP_HOMEASSISTANT>:8123`)
* **Dominio Público (HTTPS):** `https://ha.mi-homelab.cl` (vía Cloudflare Tunnel)

---

## 🚀 3. Procedimiento de Instalación Paso a Paso

### Paso 1: Conexión SSH al Servidor Proxmox

Conectarse como `root` al clúster de Proxmox:
```bash
ssh root@<IP_PROXMOX1>
```

### Paso 2: Descarga e Importación de la Imagen Oficial HAOS OVA

Home Assistant provee imágenes en formato `qcow2` optimizadas para hipervisores KVM/Proxmox.

```bash
# 1. Obtener la última versión estable oficial de HAOS OVA
wget -q -O /tmp/haos_ova.qcow2.xz https://github.com/home-assistant/operating-system/releases/download/18.2/haos_ova-18.2.qcow2.xz

# 2. Descomprimir la imagen
unxz -f /tmp/haos_ova.qcow2.xz

# 3. Crear la máquina virtual base con configuración UEFI (OVMF) y Chipset Q35
qm create 104 \
  --name HomeAssistant \
  --memory 4096 \
  --cores 2 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --bios ovmf \
  --machine q35 \
  --ostype l26 \
  --onboot 1

# 4. Crear disco EFI en el almacenamiento LUN-OMV-2TB sin llaves pre-enroladas
qm set 104 --efidisk0 LUN-OMV-2TB:0,efitype=4m,pre-enrolled-keys=0

# 5. Importar la imagen de disco de Home Assistant al almacenamiento LUN-OMV-2TB
qm importdisk 104 /tmp/haos_ova.qcow2 LUN-OMV-2TB

# 6. Asociar el disco importado a la controladora SCSI VirtIO y activar el orden de arranque
qm set 104 --scsihw virtio-scsi-single --scsi0 LUN-OMV-2TB:vm-104-disk-1,discard=on --boot "order=scsi0"

# 7. Iniciar la máquina virtual y limpiar temporales
qm start 104
rm -f /tmp/haos_ova.qcow2
```

---

## ⚙️ 4. Primer Inicio y Configuración Inicial (Onboarding)

1. Una vez iniciada la VM, abre la consola web de Proxmox en VM `104` (HomeAssistant) o revisa la tabla de DHCP de tu router/MikroTik para obtener la dirección IP asignada a la máquina virtual (ejemplo: `10.55.40.X`).
2. Abre tu navegador e ingresa a:
   `http://10.55.40.X:8123`
3. Verás la pantalla de inicio de Home Assistant indicando **"Preparing Home Assistant"** (esto toma de 2 a 5 minutos mientras instala las últimas actualizaciones del Core).
4. Crea la cuenta de administrador principal:
   * **Nombre de usuario:** `admin` (o tu nombre preferido)
   * **Contraseña:** Contraseña segura del HomeLab
   * **Ubicación:** Configura la ubicación (zona horaria `America/Santiago`).

---

## 🔐 5. Exposición Segura con Cloudflare Tunnel (HTTPS)

Para controlar tu hogar de forma remota y recibir alertas móviles con HTTPS de grado bancario sin abrir puertos en el router:

1. Ingresa a **Cloudflare Zero Trust** (`dash.cloudflare.com`).
2. Ve a **Networks** -> **Tunnels** y edita el túnel activo de `mi-homelab.cl`.
3. Agrega un nuevo **Public Hostname**:
   * **Subdomain:** `ha`
   * **Domain:** `mi-homelab.cl`
   * **Service Type:** `HTTP`
   * **URL:** `10.55.40.X:8123` (IP asignada a la VM de Home Assistant)
4. En Home Assistant, edita el archivo `configuration.yaml` (vía la extensión File Editor de la tienda de Add-ons) para permitir el proxy inverso de Cloudflare:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.X.X.0/24  # Rango de IPs locales del HomeLab
```

5. Accede de forma ultra segura a través de: `https://ha.mi-homelab.cl`

---

## 📊 6. Integración en el Dashboard de Homepage

Para integrar Home Assistant en tu panel principal de Homepage en `Rasp_Node_1`:

Agrega lo siguiente en tu `/DOCKER-DATA/homepage/config/services.yaml`:

```yaml
- Domótica y Smart Home:
    - Home Assistant:
        icon: home-assistant.png
        href: https://ha.mi-homelab.cl
        description: Panel Domótico Central
        widget:
          type: homeassistant
          url: http://10.55.40.X:8123
          key: TU_LONG_LIVED_ACCESS_TOKEN  # Generado en HA -> Perfil -> Long-Lived Access Tokens
```

---

## 💾 7. Estrategia de Respaldos y Mantenimiento

* **Snapshots de Proxmox:** Antes de actualizar la versión principal de HAOS, realiza un Snapshot instantáneo desde Proxmox VE.
* **Google Drive Backup Add-on:** Instala la extensión *"Home Assistant Google Drive Backup"* desde la tienda de Add-ons para respaldos automáticos diarios cifrados en la nube.
* **Zabbix Monitoring:** Monitorea la disponibilidad del puerto `8123` o la VM `104` directamente en tu Zabbix Server.
