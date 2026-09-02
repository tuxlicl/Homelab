# 🏠 LabHome 3D - Infrastructura & Documentacion del proyecto

Repositorio oficial del proyecto **LabHome 3D** (**mi-homelab.cl**). Contiene todas las implementaciones, arquitecturas, archivos Docker Compose y guías técnicas del HomeLab.

---

## 📂 Estructura General del Repositorio

```text
homelab/
├── implementaciones/                      # Guías y proyectos completos de infraestructura
│   ├── HomeAssistant/                     # Despliegue de Home Assistant OS en Proxmox VE
│   ├── Homepage/                          # Configuración y tema del Dashboard principal
│   ├── Integracion RSS Ghost - Make - X/  # Automatización de contenidos (Ghost -> Social)
│   ├── Obsidian/                          # Obsidian Sync y servidor CouchDB propio
│   ├── Relay de Correo/                   # Configuración del Relay SMTP local (<IP_RASP_NODE1>:2525)
│   ├── Tunnel Cloudflared Raspberry/      # Túneles de Cloudflare Zero Trust (mi-homelab.cl)
│   ├── VaultWarden/                       # Gestor de contraseñas Vaultwarden en SAGR
│   └── Zabbix/                            # Servidor y plantillas de monitoreo Zabbix
├── docker/                                # Definiciones de Docker Compose organizadas
│   └── vaultwarden/
└── docs/                                  # Guías rápidas en Markdown
```

---

## 📚 Índice de Implementaciones

### 🔐 1. [Vaultwarden (Gestor de Contraseñas)](implementaciones/VaultWarden/GUIA_DESPLIEGUE_VAULTWARDEN.md)
* **Servidor:** `SAGR` (`<IP_SAGR>:8445`)
* **Acceso Público:** `https://vault.mi-homelab.cl`
* Configuración con hash Argon2, integración con SMTP Relay local y exposición con Cloudflare Tunnel.

### 🏠 2. [Home Assistant OS en Proxmox VE](implementaciones/HomeAssistant/GUIA_DESPLIEGUE_HOME_ASSISTANT_PROXMOX.md)
* **Hypervisor:** Proxmox VE (`proxtux` / `proxtux2`)
* **Acceso Público:** `https://ha.mi-homelab.cl`
* Instalación mediante VM UEFI (q35) en disco `DATASERVER`, supervisor completo y tienda de add-ons.

### 📊 3. [Homepage Dashboard](implementaciones/Homepage/homepage_setup_guide.md)
* **Servidor:** `Rasp_Node_1` (`<IP_RASP_NODE1>:4000`)
* **Acceso Público:** `https://homepage.mi-homelab.cl`
* Dashboard interactivo con widgets de Zabbix, Grafana, OpenMediaVault, Proxmox y tema oscuro Dark Cyber.

### 📈 4. [Zabbix Monitoring Server](implementaciones/Zabbix/zabbix_deployment_guide.md)
* **Servidor:** `SAGR` (`<IP_SAGR>:8088`)
* Monitoreo de hipervisores Proxmox VE (vía API HTTP), agentes Linux, switches, NAS OMV y certificados SSL.

### 🌐 5. [Cloudflare Tunnel Zero Trust](implementaciones/Tunnel%20Cloudflared%20Raspberry/cloudflare_tunnel_guide.md)
* **Servidor:** `Rasp_Node_1` / `SAGR`
* Exposición segura HTTPS sin apertura de puertos en el router para todos los servicios de `mi-homelab.cl`.

### ✉️ 6. [Relay de Correo SMTP Local](implementaciones/Relay%20de%20Correo/smtp_relay_docs.md)
* **Servidor:** `Rasp_Node_1` (`<IP_RASP_NODE1>:2525`)
* Relay SMTP sin autenticación local para envío de alertas de Zabbix, Vaultwarden y Proxmox.

### 📝 7. [Obsidian Sync & CouchDB](implementaciones/Obsidian/obsidian-pack/GUIA_COMPLETA.md)
* Servidor propio de sincronización CouchDB para bóvedas de Obsidian en el HomeLab.

### 🤖 8. [Automatización RSS Ghost - Make - Instagram - X](implementaciones/Integracion%20RSS%20Ghost%20-%20Make%20-%20Insta:x/automatizacion-ghost-instagram-x.md)
* Pipeline de difusión automática de publicaciones de blog hacia redes sociales.

---

## 🔒 Seguridad y Privacidad

Este repositorio es **Publico** y no incluye claves privadas, tokens activos ni contraseñas en texto plano. Todos los valores sensibles están parametrizados mediante variables de entorno `.env`. y esta bajo Licencia MITT Open source
