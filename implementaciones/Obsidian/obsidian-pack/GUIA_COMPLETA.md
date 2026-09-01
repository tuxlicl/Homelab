# Guia completa: Obsidian + LiveSync en tu Homelab

## Que vas a tener al final

```
Mac (Obsidian)  <---sync--->  Homelab Rocky Linux (CouchDB en Docker)
                                    |
Celular (Obsidian) <---sync--------+
                                    |
                          Cloudflare Tunnel (obsidian.labhome.cl)
```

Un solo container Docker con 4 bases de datos separadas:
1. vault-homelab - tu infra personal
2. vault-chilquinta - trabajo
3. vault-sagr - drones, DGAC, startup
4. vault-personal - finanzas, familia, Instagram

---

## PARTE 1 — Homelab (Rocky Linux / Docker)

### Paso 1: Copiar archivos al servidor

```bash
ssh tuxli@<ip-homelab>
mkdir -p ~/docker/obsidian-sync
cd ~/docker/obsidian-sync
# Copia la carpeta obsidian-sync/ del zip aqui
```

### Paso 2: Configurar la password

```bash
mv env.txt .env
nano .env
# Cambia COUCHDB_PASSWORD por algo fuerte
```

### Paso 3: Levantar CouchDB

```bash
docker compose up -d
docker logs obsidian-sync
# Deberias ver "Apache CouchDB has started"
```

### Paso 4: Configurar CouchDB (una sola vez)

```bash
chmod +x setup-couchdb.sh
./setup-couchdb.sh
```

### Paso 5: Agregar ruta en Cloudflare Tunnel

En tu config de cloudflared:

```yaml
ingress:
  # ... tus rutas existentes ...
  - hostname: obsidian.labhome.cl
    service: http://localhost:5984
  - service: http_status:404
```

Reiniciar:
```bash
sudo systemctl restart cloudflared
```

### Paso 6: Verificar desde fuera

Desde tu Mac, en el navegador:
```
https://obsidian.labhome.cl
```
Deberia responder con `{"couchdb":"Welcome"...}`

---

## PARTE 2 — Mac (Obsidian)

### Paso 7: Instalar Obsidian

Descarga desde https://obsidian.md — instala normal.

### Paso 8: Crear los 4 vaults

Al abrir Obsidian:
1. "Create new vault"
2. Nombre: `Homelab`, ubicacion: `~/Obsidian/Homelab`
3. Repetir para `Chilquinta`, `SAGR`, `Personal`

Para cambiar entre vaults: icono de boveda (abajo izquierda) > "Open another vault"

### Paso 9: Copiar las carpetas iniciales

```bash
cp -r vaults/vault-homelab/*    ~/Obsidian/Homelab/
cp -r vaults/vault-chilquinta/* ~/Obsidian/Chilquinta/
cp -r vaults/vault-sagr/*       ~/Obsidian/SAGR/
cp -r vaults/vault-personal/*   ~/Obsidian/Personal/
```

### Paso 10: Instalar plugin LiveSync (repetir en CADA vault)

Los plugins se instalan POR VAULT. Hacer esto 4 veces:

1. Abre el vault
2. Settings > Community plugins > Turn on > confirma
3. Browse > busca "Self-hosted LiveSync"
4. Install > Enable
5. Configurar:

| Campo | Valor |
|---|---|
| Server URI | `https://obsidian.labhome.cl` |
| Username | `obsidian` |
| Password | tu password del .env |
| Database name | ver tabla abajo |

6. Click "Test" > deberia decir "Connected"
7. Elegir LiveSync (instantaneo) o Periodic Sync (cada 5 min)
8. Click "Rebuild everything" la primera vez

**Database name por vault:**

| Vault | Database name |
|---|---|
| Homelab | `vault-homelab` |
| Chilquinta | `vault-chilquinta` |
| SAGR | `vault-sagr` |
| Personal | `vault-personal` |

---

## PARTE 3 — Celular (opcional)

1. Instalar Obsidian desde App Store / Google Play
2. Crear los vaults que quieras tener en el celular
3. Instalar plugin LiveSync igual que en Mac (Paso 10)
4. Misma URI y database name

---

## Troubleshooting

| Problema | Solucion |
|---|---|
| Test falla con timeout | Revisa cloudflared y la ruta a localhost:5984 |
| Test falla con 401 | Usuario o password incorrecta en el plugin |
| Test falla con CORS | Corre setup-couchdb.sh de nuevo |
| Sync no arranca | Click "Rebuild everything" en el plugin |
| Conflicto de edicion | LiveSync resuelve auto; revisa notas _conflict |
| CouchDB no arranca | docker logs obsidian-sync |
