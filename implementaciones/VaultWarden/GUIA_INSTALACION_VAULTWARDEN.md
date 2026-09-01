# 🔐 Guía Completa de Despliegue e Integración de Vaultwarden en HomeLab

Esta guía documenta el procedimiento paso a paso para desplegar, asegurar e integrar **Vaultwarden** (gestor de contraseñas auto-hospedado compatible con Bitwarden) en el ecosistema HomeLab.

---

## 📌 1. Ficha Técnica del Servicio

* **Servidor Host:** `SAGR` (`<IP_SAGR>`)
* **Ruta de Despliegue:** `/DOCKER-DATA/vaultwarden/`
* **Puerto Interno (Host):** `8445` (Mapeado al puerto `80` del contenedor)
* **Dominio Público (HTTPS):** `https://vault.labhome.cl` (vía Cloudflare Tunnel)
* **Relay de Correo (SMTP):** `<IP_RASP_NODE1>:2525`
* **Panel de Administración:** `https://vault.labhome.cl/admin`

---

## 🚀 2. Creación de la Estructura y `docker-compose.yml`

En el servidor `SAGR`, se creó el directorio dedicado e implementó la siguiente plantilla de servicios:

```bash
mkdir -p /DOCKER-DATA/vaultwarden/data
cd /DOCKER-DATA/vaultwarden/
nano docker-compose.yml
```

### Archivo `docker-compose.yml`:
```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      - SIGNUPS_ALLOWED=false
      - TZ=America/Santiago
      # NOTA: Cada '$' del hash generado por Argon2 debe duplicarse como '$$' para evitar que Docker Compose lo interprete como variable de entorno.
      - ADMIN_TOKEN=
    volumes:
      - ./data:/data
    ports:
      - 8445:80
```

---

## 🔑 3. Generación del Hash de Seguridad para el Admin Panel

Para habilitar y proteger la ruta `/admin`, se generó un hash seguro con **Argon2id**:

1. **Generación del Hash:**
   ```bash
   docker run --rm -it vaultwarden/server:latest /vaultwarden hash
   ```
   *Se ingresa la contraseña maestra deseada en texto plano y el sistema retorna la cadena cifrada.*

2. **Formateo para Docker Compose:**
   Si la cadena generada es:
   `$argon2id$v=19$m=65540,t=3,p=4$<TU_HASH_ARGON2_AQUI>`
   
   En el archivo `docker-compose.yml` se debe guardar reemplazando los `$` por `$$`:
   `$$argon2id$$v=19$$m=65540,t=3,p=4$$<TU_HASH_ARGON2_AQUI>`

3. **Iniciación / Reinicio del Contenedor:**
   ```bash
   docker compose down && docker compose up -d
   ```

---

## 🌐 4. Exposición Segura con Cloudflare Tunnel (HTTPS)

Para cumplir con el requisito de contexto seguro (`Web Crypto API`) que exige Bitwarden/Vaultwarden para guardar contraseñas y funcionar en dispositivos móviles:

1. Ingresar al panel de **Cloudflare Zero Trust** -> **Networks** -> **Tunnels**.
2. Editar el túnel activo de `labhome.cl`.
3. Agregar un nuevo **Public Hostname**:
   * **Subdomain:** `vault`
   * **Domain:** `labhome.cl`
   * **Service Type:** `HTTP`
   * **URL:** `localhost:8445` (o `<IP_SAGR>:8445`)
4. Guardar cambios. Cloudflare provee el certificado SSL/TLS (HTTPS) de forma automática.

---

## ⚙️ 5. Configuración General y Endurecimiento (Admin Panel)

Ingresar a `https://vault.labhome.cl/admin` utilizando la contraseña en texto plano configurada en el paso 3.

### A. General Settings:
* **Domain URL:** `https://vault.labhome.cl` *(Crucial para generar enlaces internos y validar sesiones)*.
* **Allow new signups:** `Unchecked` (Desactivado / `false`). Evita que cualquier usuario no autorizado registre una cuenta en tu servidor.

---

## 📧 6. Configuración del Servidor de Correo (SMTP Relay)

En el panel `/admin`, navegar a la sección **SMTP Settings**:

* **Enabled:** `Checked` (Activado)
* **Use Sendmail:** `Unchecked`
* **Host:** `<IP_RASP_NODE1>`
* **Secure SMTP:** `none`
* **Port:** `2525`
* **From Address:** `noreply@labhome.cl`
* **From Name:** `Vault Labhome`
* **Username / Password:** (En blanco, al usar relay sin autenticación directa).

> ⚠️ **REGLA DE ORO:** Siempre se debe presionar el botón **Save** al final de la página antes de presionar el botón **Send test email**. De lo contrario, el sistema mostrará un error indicando que los cambios no han sido guardados.

---

## 📱 7. Conexión de Clientes (Navegadores y Dispositivos Móviles)

Para conectar la extensión de navegador o la aplicación móvil oficial de **Bitwarden**:

1. Descargar la aplicación oficial de **Bitwarden** en el dispositivo.
2. En la pantalla inicial de Login/Registro, presionar el ícono de **Configuración (⚙️)** en la esquina superior.
3. En el campo **Server URL / URL del servidor**, ingresar:
   `https://vault.labhome.cl`
4. Guardar y proceder a iniciar sesión con la cuenta creada.

---

## 🛠️ Comandos de Mantenimiento Rápido

* **Ver Logs en Tiempo Real:**
  ```bash
  docker logs -f vaultwarden
  ```

* **Actualizar a la Última Versión:**
  ```bash
  cd /DOCKER-DATA/vaultwarden
  docker compose pull
  docker compose up -d
  ```

* **Respaldo de Datos:**
  Toda la información cifrada residirá en la carpeta `/DOCKER-DATA/vaultwarden/data/` del host. Basta con respaldar esa carpeta.
