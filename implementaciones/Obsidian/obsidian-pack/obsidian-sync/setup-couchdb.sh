#!/bin/bash
set -e

source .env 2>/dev/null || true
USER="${COUCHDB_USER:-obsidian}"
PASS="${COUCHDB_PASSWORD:?Error: COUCHDB_PASSWORD no definida. Crea el archivo .env}"
HOST="http://${USER}:${PASS}@localhost:5984"

echo "=============================================="
echo "  Configurando CouchDB para Obsidian LiveSync"
echo "=============================================="
echo ""

echo "[*] Habilitando CORS..."
curl -s -X PUT "${HOST}/_node/_local/_config/httpd/enable_cors" -d '"true"' > /dev/null
curl -s -X PUT "${HOST}/_node/_local/_config/cors/origins" -d '"*"' > /dev/null
curl -s -X PUT "${HOST}/_node/_local/_config/cors/credentials" -d '"true"' > /dev/null
curl -s -X PUT "${HOST}/_node/_local/_config/cors/methods" -d '"GET, PUT, POST, HEAD, DELETE"' > /dev/null
curl -s -X PUT "${HOST}/_node/_local/_config/cors/headers" -d '"accept, authorization, content-type, origin, referer"' > /dev/null
echo "[OK] CORS habilitado."

echo "[*] Configurando limite de request..."
curl -s -X PUT "${HOST}/_node/_local/_config/chttpd/max_http_request_size" -d '"4294967296"' > /dev/null
echo "[OK] Limite configurado (4GB)."

echo "[*] Creando bases de datos..."
DATABASES=("vault-homelab" "vault-chilquinta" "vault-sagr" "vault-personal")

for DB in "${DATABASES[@]}"; do
    RESULT=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${HOST}/${DB}")
    if [ "$RESULT" = "201" ]; then
        echo "    [OK] ${DB} - creada"
    elif [ "$RESULT" = "412" ]; then
        echo "    [--] ${DB} - ya existia"
    else
        echo "    [!!] ${DB} - error (HTTP ${RESULT})"
    fi
done

echo ""
echo "=============================================="
echo "  Listo!"
echo ""
echo "  Bases de datos creadas:"
echo "    - vault-homelab      -> Homelab / infra personal"
echo "    - vault-chilquinta   -> Trabajo / Chilquinta"
echo "    - vault-sagr         -> SAGR / drones / startup"
echo "    - vault-personal     -> Finanzas / familia / Instagram"
echo ""
echo "  IMPORTANTE: Renombra env.txt a .env si no lo hiciste"
echo "=============================================="
