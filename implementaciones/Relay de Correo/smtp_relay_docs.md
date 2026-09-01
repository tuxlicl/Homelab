# Documentación: Despliegue de SMTP Relay local con Docker y Gmail

Este documento detalla el procedimiento para levantar un servidor SMTP Relay (usando Postfix) en un contenedor Docker. 
El objetivo de este relay es centralizar el envío de correos de tu red local (Zabbix, Ghost, Proxmox, etc.). Los dispositivos internos se conectan al relay sin necesidad de autenticación, y el relay se encarga de autenticarse de forma segura con Gmail para enviar los correos a Internet.

---

## 1. Requisitos Previos (Gmail)

Para que el relay pueda enviar correos a través de Gmail, necesitas una **Contraseña de Aplicación** (App Password), ya que Google no permite usar la contraseña normal de tu cuenta por seguridad.

1. Ingresa a tu cuenta de Google (`<TU_CORREO_AQUI>`).
2. Ve a **Gestionar tu cuenta de Google** > **Seguridad**.
3. Asegúrate de tener activada la **Verificación en dos pasos (2FA)**.
4. Busca la sección **Contraseñas de aplicaciones** (App Passwords).
5. Crea una nueva contraseña. Ponle un nombre identificativo (ej: "Docker SMTP Relay").
6. Google te dará una contraseña de 16 letras (ej: `tpgqpvdfakowkche`). Guárdala.

---

## 2. Configuración del Docker Compose

En tu servidor (ej. Raspberry Pi), crea un directorio para alojar el proyecto y dentro genera un archivo `docker-compose.yml`.

```yaml
version: '3.3'

services:
  smtp-relay:
    image: juanluisbaptiste/postfix:latest
    container_name: smtp-relay
    restart: always
    ports:
      # Exponemos el puerto 25 interno al puerto 2525 del host
      - "2525:25"
    environment:
      - SMTP_SERVER=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USERNAME=<TU_CORREO_AQUI>
      - SMTP_PASSWORD=  # Tu App Password de 16 caracteres
      - SERVER_HOSTNAME=
```

> [!TIP]
> **Puerto 2525:** Usamos el puerto 2525 en la máquina host en lugar del clásico 25, ya que algunos proveedores de internet (ISP) bloquean el puerto 25 saliente/entrante.

---

## 3. Despliegue

Abre tu terminal, navega a la carpeta donde creaste el archivo y ejecuta:

```bash
docker-compose up -d
```

Para verificar que levantó correctamente, puedes revisar los logs:
```bash
docker logs -f smtp-relay
```

---

## 4. Cómo conectar tus aplicaciones (Zabbix, Ghost, etc.)

Cualquier aplicación dentro de tu red local que necesite enviar correos, ahora debe configurarse de la siguiente manera, apuntando a tu Raspberry Pi (o donde hayas desplegado el contenedor):

* **Servidor SMTP:** `<IP_RASP_NODE1>` *(IP de la Raspberry)*
* **Puerto SMTP:** `2525`
* **Seguridad / Cifrado:** `Ninguno` (El contenedor se encarga de cifrar hacia Gmail)
* **Autenticación:** `Ninguno` (El contenedor ya tiene las credenciales)
* **Correo de origen (From):** `<TU_CORREO_AQUI>` *(Debe coincidir con la cuenta de Gmail, de lo contrario Gmail podría rechazarlo)*

> [!IMPORTANT]
> Dado que este contenedor no pide autenticación para recibir correos internamente, asegúrate de **nunca exponer el puerto 2525 a Internet** a través de tu router o proxy reverso. Solo debe ser accesible desde tu red local (LAN).
