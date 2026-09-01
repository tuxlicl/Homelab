# Guía de Despliegue: Zabbix 7.4 en Docker

Este documento detalla el procedimiento paso a paso que se llevó a cabo para la instalación y configuración del entorno de monitoreo Zabbix (versión 7.4) utilizando contenedores Docker sobre un servidor con Rocky Linux.

> [!NOTE]
> **Servidor Destino:** `sagr.geinet.cl`
> **Directorio Base:** `/DOCKER-DATA/zabbix`
> **Puerto Web Asignado:** `8088` (Debido a que el puerto 80 ya se encontraba en uso)

---

## Paso 1: Preparación del Directorio y Permisos

Lo primero fue conectarse al servidor remoto vía SSH para crear la estructura de directorios necesaria donde Zabbix almacenará su configuración, scripts y bases de datos persistentes.

Se ejecutaron los siguientes comandos para crear la carpeta principal y asignar la propiedad correcta al usuario administrador (`tuxli`):

```bash
sudo mkdir -p /DOCKER-DATA/zabbix
sudo chown -R tuxli:tuxli /DOCKER-DATA/zabbix
```

---

## Paso 2: Generación de Credenciales Seguras (`.env`)

Para mantener la base de datos segura y no exponer contraseñas en texto plano dentro del archivo de configuración, se creó un archivo de variables de entorno oculto llamado `.env` dentro de la carpeta `/DOCKER-DATA/zabbix/`.

Este archivo contenía las variables de la base de datos MariaDB:

```env
MYSQL_PASSWORD=<TU_MYSQL_PASSWORD_AQUI>
MYSQL_ROOT_PASSWORD=<TU_MYSQL_ROOT_PASSWORD_AQUI>
```

---

## Paso 3: Configuración de Docker Compose (`docker-compose.yml`)

Se redactó el archivo `docker-compose.yml` utilizando las **imágenes oficiales basadas en Alpine Linux** (`alpine-7.4-latest`), las cuales son la recomendación estándar de Zabbix por ser extremadamente ligeras, rápidas y seguras. 

> [!TIP]
> Aunque el servidor base use Rocky Linux, Docker permite correr contenedores Alpine o Ubuntu de manera aislada sin ningún conflicto a nivel de sistema operativo.

A continuación, el archivo de configuración final que se implementó. Se modificó el puerto del contenedor web de `80:8080` a `8088:8080` para evitar el conflicto con el puerto 80 del host.

```yaml
services:
  db:
    container_name: zabbix-db
    image: mariadb:10.11
    restart: unless-stopped
    volumes:
      - ./volumes/mysql:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=zabbix
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

  zabbix-server:
    image: zabbix/zabbix-server-mysql:alpine-7.4-latest
    container_name: zabbix-server
    restart: unless-stopped
    ports:
      - "10050:10050" # Agente Zabbix (Activo/Pasivo)
      - "10051:10051" # Trapper de Zabbix
    volumes:
      - ./volumes/alertscripts:/usr/lib/zabbix/alertscripts
      - ./volumes/externalscripts:/usr/lib/zabbix/externalscripts
      - ./volumes/modules:/var/lib/zabbix/modules
      - ./volumes/enc:/var/lib/zabbix/enc
      - ./volumes/ssh_keys:/var/lib/zabbix/ssh_keys
      - ./volumes/ssl/certs:/var/lib/zabbix/ssl/certs
      - ./volumes/ssl/keys:/var/lib/zabbix/ssl/keys
      - ./volumes/ssl_ca:/var/lib/zabbix/ssl/ssl_ca
      - ./volumes/snmptraps:/var/lib/zabbix/snmptraps
      - ./volumes/mibs:/var/lib/zabbix/mibs
    environment:
      - DB_SERVER_HOST=db
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    depends_on:
      - db

  zabbix-nginx:
    image: zabbix/zabbix-web-nginx-mysql:alpine-7.4-latest
    container_name: zabbix-web
    restart: unless-stopped
    ports:
      - "8088:8080"  # <--- Puerto modificado para acceso web
      - "8443:8443"
    depends_on:
      - zabbix-server
    environment:
      - DB_SERVER_HOST=db
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - PHP_TZ=America/Santiago # Configuración de Zona Horaria de Chile
      - ZBX_SERVER_HOST=zabbix-server
```

---

## Paso 4: Despliegue de los Contenedores

Una vez que los archivos `.env` y `docker-compose.yml` se transfirieron de forma segura al directorio `/DOCKER-DATA/zabbix`, nos posicionamos en la carpeta y ejecutamos el comando estándar para iniciar la orquestación en segundo plano (`-d` de *detached*):

```bash
cd /DOCKER-DATA/zabbix
docker compose up -d
```

Este comando se encargó de descargar (`pull`) las imágenes oficiales desde Docker Hub, crear la red interna para que los tres contenedores (Base de datos, Servidor Central y Panel Nginx) se comuniquen, e iniciarlos en orden respetando las directivas `depends_on`.

---

## Acceso y Credenciales por Defecto

> [!IMPORTANT]
> Una vez levantados los contenedores, el panel de administración queda expuesto y listo para el ingreso:

- **URL de Acceso:** `http://sagr.geinet.cl:8088`
- **Usuario:** `Admin` *(La "A" debe ser mayúscula)*
- **Contraseña:** `zabbix`
