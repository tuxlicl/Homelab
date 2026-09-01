# 🏠 LabHome 3D - Infrastructure & Documentation

Repositorio privado de **LabHome 3D** con las configuraciones, despliegues en Docker, Proxmox VE y documentación técnica del proyecto (**labhome.cl**).

---

## 📂 Estructura del Repositorio

```text
homelab/
├── docker/                  # Definiciones de Docker Compose y configuraciones
│   ├── vaultwarden/         # Configuración de gestor de contraseñas Vaultwarden
│   └── homepage/            # Dashboard principal (services.yaml, bookmarks.yaml, custom.css)
├── docs/                    # Guías de despliegue en formato Markdown
│   ├── GUIA_INSTALACION_VAULTWARDEN.md
│   └── GUIA_DESPLIEGUE_HOME_ASSISTANT_PROXMOX.md
└── scripts/                 # Mantenimiento y utilidades
```

---

## 🚀 Guías de Despliegue Disponibles

* 🔐 [Guía de Instalación de Vaultwarden](docs/GUIA_INSTALACION_VAULTWARDEN.md)
* 🏠 [Guía de Despliegue de Home Assistant OS en Proxmox VE](docs/GUIA_DESPLIEGUE_HOME_ASSISTANT_PROXMOX.md)
