# Automatización de publicación en RRSS: Ghost → Make → Instagram/X

**Blog:** mi-homelab.cl
**Última actualización:** 3 de julio de 2026
**Autor:** Usuario Homelab

---

## 1. ¿Qué hace esta automatización?

Cuando publicas o actualizas un artículo en Ghost (mi-homelab.cl), un webhook dispara un escenario en Make.com que:

1. Publica automáticamente en **X/Twitter** (vía el módulo nativo de Buffer).
2. Publica automáticamente en **Instagram** (vía una llamada HTTP directa a la API GraphQL nueva de Buffer).

Ambas publicaciones incluyen el título del artículo, el link y hashtags fijos, además de la imagen destacada del post.

---

## 2. Por qué existen dos métodos distintos (Buffer nativo vs HTTP)

El **25 de mayo de 2026**, Buffer migró su API pública de REST a GraphQL y **deprecó el formato legacy** (`media[picture]` / `media[thumbnail]`) que usa el módulo nativo de Buffer dentro de Make.

- **X/Twitter:** el módulo nativo de Buffer sigue funcionando bien porque ese post **no lleva imagen adjunta** (Twitter genera su propia preview del link). Por eso no se tocó.
- **Instagram:** Instagram **exige imagen obligatoria**, y el módulo nativo de Buffer con imágenes empezó a fallar con el error `400: Picture parameter passed without thumbnail parameter`. La solución fue reemplazar ese módulo por uno **HTTP** que llama directamente a la API GraphQL nueva de Buffer.

**Conclusión:** no se debe intentar "arreglar" el módulo Buffer nativo para Instagram — está construido sobre una API que Buffer ya no soporta para este caso de uso. El camino correcto es el módulo HTTP documentado aquí.

---

## 3. Estructura final del escenario en Make

```
Webhooks (Custom webhook)
   │
   ├──► Buffer 5 — Create a status update   → publica en X/Twitter (sin imagen)
   │
   └──► HTTP 17 — Make a request             → publica en Instagram (vía GraphQL)
```

> Nota: actualmente ambos módulos corren en **secuencia** (uno después del otro). Si algún día uno falla (ej. X bloquea por contenido duplicado), puede detener la ejecución del segundo. Ver sección 8 (mejoras pendientes) si se quiere separar con un Router.

### Configuración del trigger

El escenario debe estar en modo **"Immediately as data arrives"** (activado, ícono morado ON) — **no** basta con dejarlo en "Run once", ya que ese modo solo escucha una única ejecución y se desactiva después, o al editar el escenario.

📍 **Verificación:** en la parte inferior del editor de Make, junto al botón "Run once", debe estar activo el toggle **"Immediately as data arrives"**.

---

## 4. Configuración del módulo Buffer (X/Twitter) — no tocar

Este módulo sigue funcionando con el conector nativo de Buffer en Make. Configuración de referencia (no requiere cambios):

- **Profiles:** `<TU_PROFILE_ID_AQUI>` (canal X — usuario_ssh)
- **Text:** texto del post, arma automáticamente el mensaje con el título y link del artículo
- **Publication:** Post immediately
- **Attach media to the update:** `No` (false) — X no necesita imagen adjunta, genera su propia preview del link

---

## 5. Configuración del módulo HTTP (Instagram) — la solución nueva

### 5.1 Prerrequisito: API Key de Buffer

1. En Buffer → Configuración → **Personal Keys** → **Generate API Key**.
2. **Key Name:** algo descriptivo, ej. `make-labhome-automation` (esta key sirve para todos los canales, no es exclusiva de Instagram).
3. **Expiration:** elegir la **más larga disponible**. Como esto corre desatendido, una expiración corta (30 días) rompe la automatización sin aviso. Si el máximo es 90 días, poner un recordatorio en el calendario para regenerarla antes de que venza.
4. **Permisos:** dejar marcados solo:
   - `account:read`
   - `posts:read`
   - `posts:write`

   Desmarcar `account:write`, `ideas:read`, `ideas:write`, `insights:read` (no se usan, y por seguridad conviene dar el mínimo acceso necesario).
5. Generar y **guardar la key de inmediato** (Buffer solo la muestra una vez).

### 5.2 Obtener el `channelId` de Instagram (solo se hace una vez)

Estos IDs ya están confirmados y no cambian, pero se documenta el método por si hay que regenerarlos en el futuro (ej. si se reconecta la cuenta de Instagram a Buffer).

```bash
export BUFFER_KEY="tu_api_key_aqui"

# Paso 1: obtener organizationId
curl -s -X POST 'https://api.buffer.com' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BUFFER_KEY" \
  -d '{"query": "query { account { id organizations { id name } } }"}' | jq

# Paso 2: obtener channelId de cada red (usar el organizationId del paso 1)
curl -s -X POST 'https://api.buffer.com' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BUFFER_KEY" \
  -d '{"query": "query { channels(input: { organizationId: \"TU_ORG_ID\" }) { id name service } }"}' | jq
```

**IDs actuales confirmados (julio 2026):**

| Canal | Nombre | channelId |
|---|---|---|
| Instagram | @mi_usuario | `<TU_PROFILE_ID_AQUI>` |
| X/Twitter | usuario_ssh | `<TU_PROFILE_ID_AQUI>` |

### 5.3 Configuración del módulo HTTP en Make

**Tipo de módulo:** HTTP → Make a request

| Campo | Valor |
|---|---|
| Authentication type | `No authentication` |
| URL | `https://api.buffer.com` |
| Method | `POST` |
| Headers → Header 1 | Name: `Content-Type` — Value: `application/json` |
| Headers → Header 2 | Name: `Authorization` — Value: `Bearer <TU_API_KEY_REAL>` |
| Body content type | `application/json` |
| Body input method | `JSON string` (Raw) |
| Parse response | `Yes` |

### 5.4 Body content — código final funcionando

Pegar tal cual en el campo **Body content**, y luego reemplazar las variables reconstruyendo los chips desde el panel de variables de Make (ver sección 6 sobre cómo evitar errores al mapear):

```json
{
  "query": "mutation { createPost(input: { text: \"🚨 ¡Nuevo artículo en el blog!\\n{{1.post.current.title}}\\nLink: {{1.post.current.url}}\\n\\n#homelab #fyp #engineering #technology #cloud\", channelId: \"<TU_PROFILE_ID_AQUI>\", schedulingType: automatic, mode: customScheduled, dueAt: \"{{formatDate(addMinutes(now; 2); \"YYYY-MM-DDTHH:mm:ss.000\"; \"UTC\")}}Z\", assets: [{ image: { url: \"{{1.post.current.feature_image}}\" } }], metadata: { instagram: { type: post, shouldShareToFeed: true } } }) { ... on PostActionSuccess { post { id dueAt } } ... on MutationError { message } } }"
}
```

### 5.5 Explicación de cada parte del código (para poder editarlo con confianza)

| Parte | Qué hace |
|---|---|
| `text: "🚨 ¡Nuevo artículo...\\n{{1.post.current.title}}\\nLink: {{1.post.current.url}}..."` | Arma el texto del post: emoji, título real del artículo (tomado del webhook), link real, y hashtags fijos. Los `\\n` son saltos de línea (doble backslash porque el JSON está anidado dentro de otro JSON). |
| `channelId: "<TU_PROFILE_ID_AQUI>"` | Fijo — apunta siempre al canal de Instagram. No usar variable aquí. |
| `schedulingType: automatic` | Requerido por Buffer, valor fijo. |
| `mode: customScheduled` | Le dice a Buffer que publique en una hora programada por nosotros (no en la cola normal). Es lo que permite "publicar ya" en vez de esperar el horario configurado en Buffer. |
| `dueAt: "{{formatDate(addMinutes(now; 2); ...; \"UTC\")}}Z"` | Calcula "ahora + 2 minutos" **en UTC real** (el tercer parámetro `"UTC"` es obligatorio, si se omite Make usa la hora de Chile y Buffer la rechaza por estar "en el pasado"). El margen de 2 minutos evita que la hora ya haya pasado al momento en que Buffer procesa la solicitud. |
| `assets: [{ image: { url: "{{1.post.current.feature_image}}" } }]` | URL de la imagen destacada real del artículo de Ghost. |
| `metadata: { instagram: { type: post, shouldShareToFeed: true } }` | Ambos campos son **obligatorios** para Instagram vía esta API: `type: post` (no story ni reel) y `shouldShareToFeed: true`. Sin esto, Buffer rechaza la publicación. |
| `{ ... on PostActionSuccess {...} ... on MutationError {...} }` | Le pide a la API que devuelva el `id` del post si funcionó, o el `message` de error si algo falló — así se puede diagnosticar directo desde el Output de Make. |

### 5.6 Nombres reales de los campos del webhook (referencia)

El payload que manda Ghost tiene esta estructura (confirmada real, no asumida):

```
post
 └── current
       ├── title              ← título del artículo
       ├── url                ← link público del artículo
       ├── feature_image      ← URL de la imagen destacada
       ├── plaintext          ← contenido en texto plano
       └── ... (otros campos)
```

**Importante:** el nivel `current` es obligatorio en la referencia (`1.post.current.title`, no `1.post.title`). Este fue el bug más difícil de encontrar durante la configuración inicial — omitir `current` hace que el campo llegue vacío sin marcar error visual en Make.

---

## 6. Cómo insertar las variables sin romper el código (lección aprendida)

Durante la configuración se detectaron dos errores recurrentes al editar el JSON a mano:

1. **Texto placeholder sin borrar completo** (ej. dejar "CCC" pegado después de insertar un chip) — esto invalida la URL o el texto sin que se note a simple vista.
2. **Chips mal formados** al escribir manualmente en vez de usar el selector de variables (ej. `{{Bundle}}{{1.Text}}` en vez de una sola referencia válida).

**Método recomendado para modificar este JSON en el futuro:**

1. Seleccionar **todo** el contenido del campo Body content y borrarlo.
2. Pegar el JSON completo de la sección 5.4, con placeholders de una sola palabra donde antes iban las variables (ej. `TITULO`, `URLIMG`).
3. Hacer **doble clic** sobre cada placeholder (selecciona la palabra completa automáticamente).
4. Con la palabra seleccionada, abrir el panel de variables (ícono de mapa a la derecha del campo) y hacer clic en el campo correspondiente para insertarlo — nunca escribirlo a mano.
5. Verificar visualmente que cada variable quedó como un **chip de color**, no como texto plano.
6. Guardar y probar con un artículo real antes de dar por cerrado el cambio.

---

## 7. Cómo probar cambios sin arriesgar una publicación real

Para probar el código directamente en la API de Buffer sin pasar por Make (útil para diagnosticar errores nuevos):

```bash
export BUFFER_KEY="tu_api_key_aqui"

curl -s -X POST 'https://api.buffer.com' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BUFFER_KEY" \
  -d '{"query": "mutation { createPost(input: { text: \"Prueba\", channelId: \"<TU_PROFILE_ID_AQUI>\", schedulingType: automatic, mode: addToQueue, saveToDraft: true, assets: [{ image: { url: \"https://placehold.co/1080x1080.jpg\" } }], metadata: { instagram: { type: post, shouldShareToFeed: true } } }) { ... on PostActionSuccess { post { id } } ... on MutationError { message } } }"}' | jq
```

`saveToDraft: true` deja el post como borrador en Buffer — no se publica de verdad, ideal para probar cambios de sintaxis sin ensuciar el feed de Instagram.

---

## 8. Cómo diagnosticar un error futuro (checklist rápido)

Si la automatización vuelve a fallar, revisar en este orden:

1. **¿El escenario está en "Immediately as data arrives" (ON)?** Si se editó el escenario recientemente, Make a veces lo desactiva. Revisar el toggle en el editor.
2. **¿La ejecución en History dice "Instant" (⚡) o "Manual run"?** Si dice "Manual run", el webhook real no se disparó — el problema está en Ghost o en el trigger, no en el código.
3. **Abrir el módulo HTTP → pestaña Input** de la ejecución fallida y revisar el `Body content` ya resuelto:
   - Si `text` o `url` están **vacíos** (`\"\"`) → problema de mapeo de variables (revisar sección 5.6 y 6).
   - Si la URL tiene texto extra pegado (ej. "CCC" al final) → placeholder mal borrado.
4. **Revisar la pestaña Output** de esa misma ejecución:
   - `"message": "Image URL is not accessible..."` → la URL de la imagen no es válida o está vacía.
   - `"message": "dueAt must be in the future"` → revisar que `formatDate` tenga el tercer parámetro `"UTC"`.
   - `"message": "Instagram posts require..."` → falta algún campo obligatorio en `metadata.instagram`.
5. **¿La API Key de Buffer expiró?** Revisar en Buffer → Personal Keys la fecha de expiración.
6. Si nada de lo anterior calza, probar el comando `curl` de la sección 7 con los mismos datos, para aislar si el problema está en Make o en la API de Buffer.

---

## 9. Mejoras pendientes (no urgentes)

- **Separar los módulos en paralelo con un Router:** actualmente Buffer (X) y HTTP (Instagram) corren en secuencia. Si X falla (ej. por contenido duplicado, como pasó en una prueba), Instagram no llega a ejecutarse. Un Router después del Webhook permitiría que ambos corran de forma independiente.
- **Recordatorio de expiración de API Key:** agendar la renovación antes de que venza, según lo elegido en el paso 5.1.
- **Formato de imagen para Instagram:** las imágenes muy anchas o panorámicas generan barras negras (letterboxing) en el post. Si se quiere evitar, usar imágenes destacadas en proporción cuadrada (1:1) o vertical (4:5) para los artículos que se publicarán en RRSS.

---

## 10. Resumen de la causa raíz (para referencia histórica)

| # | Problema | Causa | Solución |
|---|---|---|---|
| 1 | Error `400: Picture parameter passed without thumbnail parameter` | Buffer deprecó su API REST legacy el 25/05/2026 | Reemplazar el módulo Buffer nativo de Instagram por un módulo HTTP a la API GraphQL nueva |
| 2 | `Instagram posts require at least one image... and a type` | Faltaban campos obligatorios de Instagram | Agregar `assets` con imagen y `metadata.instagram.type: post` |
| 3 | `Field shouldShareToFeed... required` | Campo obligatorio faltante | Agregar `shouldShareToFeed: true` |
| 4 | `dueAt must be in the future` | `formatDate` sin zona horaria usaba hora de Chile marcada como si fuera UTC | Agregar `"UTC"` como tercer parámetro de `formatDate` |
| 5 | `Image URL is not accessible` (con datos reales) | Referencia de campo incompleta: faltaba el nivel `current` | Cambiar `1.post.feature_image` → `1.post.current.feature_image` |
| 6 | Publicaba pero sin encabezado/formato | El texto solo usaba el título, sin la plantilla completa | Armar el texto con emoji + título + link + hashtags, replicando el formato del post de X |

