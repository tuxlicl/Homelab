# 🎛️ Diagramas 3D de Arquitectura e Infraestructura de Rack: LabHome 3D

Este documento contiene los **dos esquemas 3D completos** del rack de **LabHome 3D**:
1. **Diagrama 1 (Macro):** Mapa físico y conexionado de puertos (apto para publicación pública, sin direcciones IP).
2. **Diagrama 2 (Micro):** Especificación ultra-detallada interna (con direcciones IP, puertos de servicio, IDs de máquinas virtuales, contenedores Docker y volúmenes de almacenamiento).

---

## 🌐 1. Diagrama 1: Macro Arquitectura 3D y Conexionado de Rack (Público)

Este esquema representa la distribución física en el gabinete de rack (U1 a U12), la jerarquía de red y la función de cada cable de interconexión.

![Simulación 3D del Rack Físico - Visión Macro](img/macro_rack_3d.jpg)

### 📐 Mapa Físico del Gabinete por Unidades de Rack (RU)

```mermaid
graph TD
    subgraph RACK["🗄️ GABINETE RACK 19\" (LabHome 3D)"]
        direction TB
        U01["U01 - 🔌 PDU / Distribución de Energía PDU-01"]
        U02["U02 - ⚡ UPS Respaldado (Onduladora de Respaldo)"]
        U03["U03 - 🌐 Firewall Router MikroTik (WAN / Gateway Main)"]
        U04["U04 - 🔀 Switch MikroTik Core (10GbE SFP+ Trunk)"]
        U05["U05 - 🔀 Switch TP-Link (24 Puertos PoE / Acceso LAN)"]
        U06["U06 - 🗂️ Patch Panel Cat6 (24 Puertos RACK-PP1)"]
        U07["U07 - 🖥️ Servidor Proxmox Node 1 ('proxtux' - 1U)"]
        U08["U08 - 🖥️ Servidor Proxmox Node 2 ('proxtux2' - 1U)"]
        U09["U09 - 💾 NAS OpenMediaVault ('Nastux' - Array Discos)"]
        U10["U10 - 🍓 Cluster Tray Raspberry Pi (Node 1 & Master)"]
    end
```

### 🔌 Cableado y Conexiones de Puerto a Puerto (Macro)

| Origen (Puerto) | Destino (Puerto) | Tipo de Cable | Función / Tráfico |
| :--- | :--- | :--- | :--- |
| **Ont ISP / Modem** | **MikroTik Firewall (Port 1)** | Cat6 UTP (Rojo) | Enlace WAN principal a Internet |
| **MikroTik Firewall (Port 2)** | **Switch MikroTik Core (SFP+ 1)** | 10G DAC Cable | Troncal Gateway LAN principal |
| **Switch MikroTik Core (Port 1)** | **Proxmox Node 1 (Eth0)** | Cat6 UTP (Azul) | Red de Gestión e Hipervisor Node 1 |
| **Switch MikroTik Core (Port 2)** | **Proxmox Node 2 (Eth0)** | Cat6 UTP (Azul) | Red de Gestión e Hipervisor Node 2 |
| **Switch MikroTik Core (Port 3)** | **NAS Nastux (Eth0)** | Cat6 UTP (Verde) | Enlace SAN / iSCSI de Alta Velocidad |
| **Switch MikroTik Core (Port 4)** | **NAS Nastux (Eth1)** | Cat6 UTP (Verde) | Enlace NAS Datos / Compartidos |
| **Switch TP-Link (Port 1)** | **Raspberry Node 1 (Eth0)** | Cat6 UTP (Amarillo) | Servidor Web Dashboard / Proxy |
| **Switch TP-Link (Port 2)** | **Raspberry Master (Eth0)** | Cat6 UTP (Amarillo) | Agente de Gestión Dockhand |
| **Switch TP-Link (SFP+ 1)** | **Switch MikroTik Core (SFP+ 2)** | 10G DAC Cable | Enlace de Interconexión entre Switches |

---

## 🔍 2. Diagrama 2: Micro Arquitectura 3D y Especificación Interna (Ultra Detallado)

Este mapa técnico desglosa la infraestructura completa: direcciones IP, subredes, identificadores de máquinas virtuales (VMID), puertos de contenedores Docker, almacenamiento iSCSI y túneles de exposición.

![Modelo 3D Blueprint de Arquitectura Interna y Nodos](img/micro_rack_3d.jpg)

### 🧠 Diagrama de Flujo Técnico Completo (IPs, VMs, Docker, Puertos)

```mermaid
flowchart TB
    subgraph ROUTER["🔥 ROUTER & FIREWALL MIKROTIK (10.55.40.1)"]
        DHCP["Servidor DHCP / DNS Local"]
        VLAN10["VLAN 10: Management (10.55.40.0/24)"]
    end

    subgraph PROXTUX["🖥️ PROXMOX NODE 1: proxtux (10.55.40.5)"]
        VM100["VM 100: Winsrvr2025\n• IP: 10.55.40.9\n• Estado: Detenido\n• RAM: 11GB"]
        VM102["VM 102: SAGR (Ubuntu Server)\n• IP: 10.55.40.7\n• RAM: 8GB | Disco: 45GB"]
        VM103["VM 103: RJ (Jump Host)\n• IP: 10.55.40.8\n• RAM: 4GB"]
        
        subgraph DOCKER_SAGR["🐳 Docker Engine en VM 102 (SAGR)"]
            VW["🔐 Vaultwarden\n• Puerto: 8445\n• URL: https://vault.labhome.cl"]
            ZBX["📈 Zabbix Server\n• Puerto: 8088 (Web/API)\n• API Token: Configurado"]
            GF["📊 Grafana\n• Puerto: 3000\n• Dashboards & Canvas"]
        end
    end

    subgraph PROXTUX2["🖥️ PROXMOX NODE 2: proxtux2 (10.55.40.6)"]
        VM104["🏠 VM 104: HomeAssistant (HAOS 18.2)\n• IP: 10.55.40.X\n• Puerto: 8123\n• URL: https://ha.labhome.cl\n• RAM: 5GB | Cores: 3 | Bios: UEFI (Q35)"]
    end

    subgraph NAS["💾 STORAGE NAS: Nastux / OpenMediaVault (10.55.40.4)"]
        ISCSI["📦 Target iSCSI: LUN-OMV-2TB (1.6TB Libre)"]
        DATASERVER["⚡ Pool Local Proxmox: DATASERVER (280GB NVMe/SSD)"]
    end

    subgraph RASP1["🍓 RASPBERRY NODE 1 (10.55.40.10 - SSH: 9999)"]
        HP["📊 Homepage Dashboard\n• Puerto: 4000\n• URL: https://homepage.labhome.cl"]
        GW["🌐 GeinetWeb\n• Puerto: 8080"]
        SMTP["✉️ SMTP Relay Local\n• Puerto: 2525"]
        CF["☁️ Cloudflared Tunnel Daemon\n• Exposición HTTPS Zero Trust"]
    end

    subgraph RASP_MASTER["🍓 RASPBERRY MASTER (10.55.40.252 - SSH: 9999)"]
        DH["⚓ Dockhand Hawser Agent\n• Puerto: 3000"]
    end

    %% Relaciones y Flujos
    PROXTUX -->|iSCSI Volume| ISCSI
    PROXTUX2 -->|Local SSD Storage| DATASERVER
    VM102 -->|Docker Container| DOCKER_SAGR
    CF -->|Proxy Reverso HTTPS| VW
    CF -->|Proxy Reverso HTTPS| HP
    CF -->|Proxy Reverso HTTPS| VM104
    ZBX -->|Alertas Email| SMTP
```

---

### 📋 Inventario Ultra-Detallado por Periférico y Recursos

| Periférico / Nodo | IP / Puerto SSH | Componente / VM / Docker | ID / Puerto Servicio | Almacenamiento / Notas |
| :--- | :--- | :--- | :--- | :--- |
| **Proxmox Node 1 (`proxtux`)** | `10.55.40.5:22` | **VM 100 (Winsrvr2025)** | VMID `100` | 100 GB Disk (Detenido) |
| | | **VM 102 (SAGR)** | VMID `102` | 45 GB Disk (Ubuntu 24.04 LTS) |
| | | ├─ Container `vaultwarden` | `8445` -> HTTPS `vault.labhome.cl` | Data: `/DOCKER-DATA/vaultwarden` |
| | | ├─ Container `zabbix-server` | `8088` (API / Web) | Database: MySQL Zabbix |
| | | └─ Container `grafana` | `3000` | Dashboards, Canvas, Zabbix Datasource |
| | | **VM 103 (RJ)** | VMID `103` | 32 GB Disk (Jump Server) |
| **Proxmox Node 2 (`proxtux2`)** | `10.55.40.6:22` | **VM 104 (HomeAssistant)** | VMID `104` | 32 GB en `DATASERVER` (HAOS 18.2 UEFI) |
| **OpenMediaVault (`Nastux`)** | `10.55.40.4:22` | **Storage Targets** | iSCSI / LVM | `LUN-OMV-2TB` (1.6TB Libre) |
| **Raspberry (`Rasp_Node_1`)** | `10.55.40.10:9999` | **Homepage Dashboard** | `4000` | Config: `/DOCKER-DATA/homepage` |
| | | **GeinetWeb** | `8080` | Config: `/DOCKER-DATA/geinetweb` |
| | | **SMTP Relay Local** | `2525` | Relay sin auth hacia Gmail |
| | | **Cloudflared Daemon** | Tunnel Active | Túnel Zero Trust (`labhome.cl`) |
| **Raspberry (`Rasp_Node_Master`)** | `10.55.40.252:9999` | **Dockhand Hawser** | `3000` | Agente gestor de Docker |
