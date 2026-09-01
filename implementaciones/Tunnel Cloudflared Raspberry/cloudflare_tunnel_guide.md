# Guía Definitiva: Cómo Configurar un Túnel de Cloudflare en una Raspberry Pi Paso a Paso

Esta guía está diseñada para que cualquier persona, incluso sin conocimientos avanzados de redes, pueda exponer los servicios alojados en su **Raspberry Pi** (como un blog, aplicaciones en Docker, Pi-hole o servidores web) hacia el internet de forma segura, **sin tener que abrir puertos en su router** ni exponer su dirección IP pública.

---

## 💡 ¿Qué es un Túnel de Cloudflare y por qué lo usamos?

Tradicionalmente, si querías que alguien entrara a tu Raspberry Pi desde internet, tenías que entrar a la configuración de tu router y abrir los puertos (Port Forwarding 80 y 443). Esto es peligroso porque expone tu red doméstica a ataques y bots maliciosos.

**Cloudflare Tunnel (Zero Trust)** cambia esto por completo:
En lugar de abrir una puerta desde afuera hacia adentro, instalamos un pequeño programa (`cloudflared`) dentro de tu Raspberry Pi. Este programa "llama" a Cloudflare desde adentro hacia afuera y crea un túnel seguro. Todo el tráfico de tus visitantes pasa primero por los potentes escudos de Cloudflare y luego viaja por el túnel hasta tu red local.

### Mejoras y Beneficios de esta configuración:
1. **Seguridad Total:** Tu IP pública real queda oculta y protegida.
2. **Cero configuración en el Router:** No hay que lidiar con tu proveedor de internet para abrir puertos.
3. **Certificados SSL Gratis:** Cloudflare se encarga de darte el candadito verde (HTTPS) automáticamente.
4. **Protección Anti-DDoS:** Los servidores de Cloudflare bloquean ataques masivos, ahorrándole todo ese trabajo al procesador (CPU) de tu Raspberry.
5. **Caché y Velocidad:** Cloudflare guarda copias de tus imágenes, lo que es vital para que tu Raspberry no se sature al recibir muchas visitas.

---

## 🛠️ Requisitos Previos

Antes de empezar, necesitas:
1. **Una Raspberry Pi** (recomendado Pi 3, 4 o 5) conectada a tu red y encendida, corriendo Raspberry Pi OS (Raspbian) o Ubuntu.
2. **Acceso a la terminal de tu Raspberry** (ya sea conectándole un teclado y monitor, o conectándote remotamente vía SSH desde tu PC usando programas como PuTTY o Royal TSX).
3. **Un dominio propio** (ejemplo: `midominio.com`).
4. **Una cuenta gratuita en Cloudflare** con tu dominio ya agregado y los "Nameservers" (DNS) apuntando a Cloudflare.

---

## 🚀 PASO 1: Crear el Túnel en Cloudflare Zero Trust

Vamos a crear el túnel desde la interfaz web de Cloudflare.

1. Inicia sesión en tu cuenta de [Cloudflare](https://dash.cloudflare.com) desde tu navegador web.
2. En el menú de la izquierda, haz clic en **Zero Trust** (es posible que te pida elegir un plan, selecciona el **Plan Gratuito**).
3. Dentro del panel de Zero Trust, ve al menú izquierdo y selecciona **Networks** > **Tunnels**.
4. Haz clic en el botón azul **Create a tunnel** (Crear un túnel).
5. Selecciona **Cloudflared** (la opción recomendada) y haz clic en Next.
6. Ponle un nombre a tu túnel. Te recomiendo algo que identifique a tu placa, por ejemplo: `RaspberryPi-Homelab`. Haz clic en **Save tunnel**.

---

## 💻 PASO 2: Instalar el Conector (`cloudflared`) en tu Raspberry Pi

Ahora Cloudflare te mostrará una pantalla con instrucciones para instalar el túnel. Como estamos usando una Raspberry Pi, la arquitectura del procesador es diferente a la de un PC normal (usa procesadores ARM).

1. En la pantalla de instalación, bajo la sección "Choose your environment" (Elige tu entorno), selecciona **Debian** (que es la base del sistema operativo de la Raspberry).
2. Justo debajo, en la arquitectura, **NO** selecciones 64-bit (eso es para PC). Selecciona **`arm64-bit`** (si usas un sistema operativo de 64 bits en tu Raspberry 4 o 5) o **`arm32-bit`** (si usas el clásico Raspberry Pi OS de 32 bits).
3. Verás que te genera un comando de instalación parecido a este (el enlace terminará en `.deb`):
   ```bash
   curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb && sudo dpkg -i cloudflared.deb && sudo cloudflared service install eyJh... (un código súper largo secreto) ...
   ```
4. **Copia todo ese comando**.
5. Abre la consola/terminal de tu Raspberry Pi (vía SSH).
6. Pega el comando y presiona **Enter**.
7. La Raspberry descargará el programa, lo instalará y lo configurará como un servicio en segundo plano. Si te pide contraseña, pon la de tu usuario de la Raspberry.
8. Vuelve a la página web de Cloudflare. En la parte inferior, donde dice *Connectors*, deberías ver que de pronto aparece tu Raspberry con el estado en verde **"Connected"**.
9. ¡Haz clic en **Next**!

---

## 🔗 PASO 3: Conectar tu Dominio con los Servicios de tu Raspberry

Ahora le vamos a decir al túnel: *"Cuando alguien escriba mi dominio, mándalos a esta aplicación dentro de mi Raspberry"*.

1. En la pestaña de **Public Hostnames**, haz clic en **Add a public hostname**.
2. **Public Hostname (La URL pública que verá el usuario):**
   * **Subdomain:** (Opcional). Si quieres que sea `blog.midominio.com`, escribe `blog`. Si quieres usar tu dominio raíz (`midominio.com`), déjalo vacío.
   * **Domain:** Selecciona tu dominio de la lista desplegable.
   * **Path:** Déjalo vacío.
3. **Service (Tu servicio local en la Raspberry):**
   * **Type:** Selecciona **HTTP** (incluso si tu aplicación local no tiene certificado SSL, Cloudflare se lo pondrá por ti en internet).
   * **URL:** Escribe la dirección IP local y el puerto donde corre tu aplicación en tu Raspberry. 
     * *Ejemplo 1:* Si estás corriendo tu blog directo en la Raspberry en el puerto 2368, escribe `localhost:2368`.
     * *Ejemplo 2:* Si quieres exponer el panel de Pi-hole que corre en la misma máquina, escribe `localhost:80`.
4. Haz clic en **Save hostname**.

**¡Felicidades!** En un par de minutos, si entras a tu dominio desde tu celular (usando datos móviles, desconectado de tu WiFi), deberías ver la página que tienes alojada en tu Raspberry Pi funcionando perfectamente en internet, de forma segura.

---

## 🛡️ PASO 4: Mejoras de Seguridad Recomendadas en Cloudflare

Ya que todo el tráfico del mundo pasa primero por Cloudflare antes de llegar a tu pequeña Raspberry, vamos a activar configuraciones para blindarla.

Ve al panel normal de Cloudflare (no el de Zero Trust) y selecciona tu dominio.

1. **Forzar HTTPS:**
   * Ve a **SSL/TLS** > **Edge Certificates**.
   * Activa la opción **Always Use HTTPS** (Usar siempre HTTPS). Esto asegura que toda conexión esté cifrada.
2. **Optimización (Crucial para aliviar tu Raspberry):**
   * Ve a **Speed** > **Optimization**.
   * Activa **Auto Minify** para JavaScript, CSS y HTML. Esto comprime los archivos para que a la Raspberry le cueste menos trabajo enviarlos.
   * Activa **Brotli** para mejor compresión.
3. **Bot Fight Mode (Modo Anti-Bots):**
   * Ve a **Security** > **Bots**.
   * Activa **Bot Fight Mode**. Esto frenará a los atacantes y escáneres que andan rondando por internet, evitando que sobrecarguen el CPU de tu Raspberry.

---

## ❓ Preguntas Frecuentes (Resolución de problemas en Raspberry)

* **El conector de Cloudflare me da error al instalar:**
  Asegúrate de haber elegido correctamente la arquitectura en el Paso 2 (`arm64` o `arm32`). Si bajaste la versión de PC (`amd64`), el procesador ARM de la Raspberry no entenderá el archivo y fallará la instalación. Si no estás seguro de tu arquitectura, escribe `uname -m` en la terminal de tu Raspberry; si dice `aarch64` es de 64 bits, si dice `armv7l` es de 32 bits.
* **Mi sitio dice "Bad Gateway" o "Error 502":**
  Esto significa que el túnel funciona perfecto, pero tu aplicación dentro de la Raspberry no está encendida, o te equivocaste en el puerto (Paso 3). 
* **¿Qué pasa si se reinicia mi Raspberry Pi o se corta la luz?**
  No te preocupes. Al instalarlo en el Paso 2, configuramos `cloudflared` como un *servicio del sistema*. Esto significa que tu túnel se reconectará automáticamente de forma mágica en cuanto tu Raspberry recupere la energía y el internet.
