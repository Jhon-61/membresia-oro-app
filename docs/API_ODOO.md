# API entre la app y Odoo

Contrato que el módulo `membresia_oro` de Odoo implementa para la app Flutter.
Módulos: `C:\Users\nder1\Music\chamba\modulos\membresia-oro-odoo`.
Si cambia un campo, actualizar **los tres lugares**: este documento, `app/lib/models/afiliacion.dart`
y el controlador del módulo. Las pruebas de `app/test/afiliacion_odoo_test.dart` verifican el lado de la app.

---

## POST `/api/membresia/v1/afiliaciones`

Crea una solicitud de afiliación. **Todavía sin pago**: el miembro queda en estado `pendiente`.

### Petición

```
POST https://<base-odoo>/api/membresia/v1/afiliaciones
Content-Type: application/json
Accept: application/json
```

```json
{
  "titular": {
    "nombre": "Ana López",
    "dpi": "1234567890101",
    "telefono": "55551234",
    "email": "ana@correo.com",
    "direccion": "Zona 1, Guatemala",
    "nit": "CF",
    "password": "Prueba2026"
  },
  "dpi_frente":  { "nombre_archivo": "frente.jpg",  "mime": "image/jpeg", "base64": "..." },
  "dpi_reverso": { "nombre_archivo": "reverso.jpg", "mime": "image/jpeg", "base64": "..." },
  "beneficiarios": [
    {
      "nombre": "Luis López",
      "dpi": "1234567890101",
      "parentesco": "hijo",
      "fecha_nacimiento": "2010-05-03"
    }
  ],
  "mascota": {
    "nombre": "Firulais",
    "especie": "perro",
    "raza": "Mestizo",
    "peso_kg": 28.5,
    "foto": { "nombre_archivo": "perro.jpg", "mime": "image/jpeg", "base64": "..." }
  },
  "firma": { "nombre_archivo": "firma.png", "mime": "image/png", "base64": "..." },
  "acepta_terminos": true,
  "version_terminos": "borrador-2026-10",
  "origen": "app_android"
}
```

| Campo | Tipo | Reglas |
|---|---|---|
| `titular.nombre` | texto | Obligatorio |
| `titular.dpi` | texto | 13 dígitos, solo números. **Único**: no puede existir otro cliente con el mismo DPI |
| `titular.telefono` | texto | 8 dígitos sin `+502` |
| `titular.email` | texto | Correo válido, en minúsculas |
| `titular.direccion` | texto | Obligatorio |
| `titular.password` | texto | Contraseña de la cuenta de la app: 8–128 caracteres, con letras y números. Se crea un usuario de portal con login = correo. Si el correo ya tiene cuenta → `422` en `titular.email` |
| `titular.nit` | texto | `"CF"` o NIT sin guiones (puede terminar en `K`), con **dígito verificador válido** (mismo algoritmo que `base_vat` de Odoo). Se guarda en el campo estándar `vat`; con CF queda vacío |
| `dpi_frente`, `dpi_reverso` | archivo | Obligatorios. JPEG/PNG, máx. 5 MB cada uno (la app los comprime a ~200 KB) |
| `beneficiarios` | lista | De 0 a 4 elementos |
| `beneficiarios[].parentesco` | texto | `conyuge`, `hijo`, `padre`, `madre`, `hermano`, `abuelo`, `nieto`, `otro` |
| `beneficiarios[].fecha_nacimiento` | fecha | `AAAA-MM-DD`, no futura |
| `mascota` | objeto o `null` | `null` si no registró mascota |
| `mascota.especie` | texto | `perro`, `gato`, `otra` |
| `mascota.peso_kg` | número | > 0. Si es > 25, **no se rechaza**: se marca `cargo_extra = True` |
| `firma` | archivo | PNG, obligatorio |
| `acepta_terminos` | booleano | Debe ser `true` |
| `version_terminos` | texto | Guardar con el miembro (qué versión de términos firmó) |
| `origen` | texto | `app_android`, `app_ios`, `web` |

Formato de archivo: `base64` es el contenido **sin** prefijo `data:image/...;base64,`.
Se puede asignar directo a un `fields.Image` / `fields.Binary` de Odoo.

### Respuestas

**201 · cliente nuevo**
```json
{
  "ok": true, "miembro_id": 123, "referencia": "MO-000123", "cliente_existente": false,
  "url_pago": "https://<odoo>/my/invoices/45?access_token=...",
  "token": "<token de sesión>"
}
```
`url_pago`: página de la factura de la primera cuota en el portal de Odoo, donde se paga en línea
(proveedor Demo en pruebas, Cybersource después). Puede ser `null` si Odoo no pudo crear la factura
(la afiliación se guarda igual). La app solo abre enlaces `https`. Al quedar pagada la factura, el
miembro pasa de `pendiente` a `activo`.

**200 · la persona ya era cliente en Odoo** (se le agregó la membresía)
```json
{
  "ok": true, "miembro_id": 45, "referencia": "MO-000124", "cliente_existente": true,
  "aviso": "Ya estabas registrado como cliente: agregamos la Membresía Oro a tu cuenta."
}
```
La app muestra el `aviso` en la pantalla de éxito.

#### Clientes que ya existen en Odoo
Se busca en este orden: **DPI → correo → teléfono** (últimos 8 dígitos, sin importar el formato).
- **Un cliente coincide** y no es miembro: se le agrega la membresía. Sus datos (nombre, correo,
  teléfono, dirección, NIT) **no se cambian**; solo se completan los vacíos. Las diferencias quedan en
  el historial y el cliente se marca **"Por revisar"** en Odoo.
- **Varios clientes coinciden**: se crea uno nuevo, marcado "Por revisar" como posible duplicado.
- **Ya es miembro**: se rechaza con `422` y el error en el campo que coincidió.

**422 · datos inválidos** (la app muestra cada error)
```json
{
  "ok": false,
  "mensaje": "Revisa los datos marcados.",
  "errores": { "titular.dpi": "Ya existe un miembro con este DPI" }
}
```
Las claves de `errores` usan la ruta del campo: `titular.dpi`, `beneficiarios.0.dpi`, `mascota.peso_kg`.

**400 · el cuerpo no es JSON**
```json
{ "ok": false, "mensaje": "La solicitud debe ser JSON." }
```

**500 · error del servidor**
```json
{ "ok": false, "mensaje": "Ocurrió un error, intenta más tarde." }
```
Nunca devolver la traza de Python ni datos internos al cliente.

### Lo que Odoo DEBE validar de nuevo

La app valida para ayudar al usuario, pero **la app se puede manipular**. El módulo vuelve a validar
todo lo de la tabla, más: tamaño y tipo real de las imágenes, DPI duplicado y máximo de 4 beneficiarios.

---

## Sesión y "Mi membresía"

Las rutas protegidas reciben `Authorization: Bearer <token>`. El token lo devuelven la afiliación y
el inicio de sesión; Odoo solo guarda su huella (SHA-256) y vence a los 90 días.

| Ruta | Método | Auth | Qué hace |
|---|---|---|---|
| `/api/membresia/v1/sesion` | POST `{email, password}` | — | `200 {ok, token, membresia}` · `401` credenciales incorrectas · `429` demasiados intentos |
| `/api/membresia/v1/sesion` | DELETE | Bearer | Cierra la sesión (invalida el token) |
| `/api/membresia/v1/sesion/recuperar` | POST `{email}` | — | Envía el correo de Odoo para crear contraseña nueva. Siempre `200` con el mismo mensaje |
| `/api/membresia/v1/membresia` | GET | Bearer | `200 {ok, membresia}` · `401` sesión vencida |

`membresia`:
```json
{
  "referencia": "MO-000007", "nombre": "Ana López", "email": "ana@correo.com",
  "telefono": "+502 55551234", "direccion": "Zona 1", "nit": "CF",
  "estado": "pendiente|activo|mora|suspendido|cancelado", "estado_texto": "Pendiente de pago",
  "fecha_alta": "2026-10-14", "dias_atraso": 0,
  "carencia": {
    "humano":  { "fecha": "2027-01-12", "dias_restantes": 90 },
    "mascota": { "fecha": "2026-11-13", "dias_restantes": 30 }
  },
  "beneficiarios": [{ "id": 1, "nombre": "...", "dpi": "...", "parentesco": "hijo",
                      "fecha_nacimiento": "2010-05-03",
                      "carencia": { "fecha": "...", "dias_restantes": 90 } }],
  "mascotas": [{ "id": 1, "nombre": "...", "especie": "perro", "raza": "...", "peso_kg": 28.5,
                 "cargo_extra": true }],
  "cuotas": [{ "id": 3, "numero": "INV/2026/00003", "periodo": "2026-10", "fecha": "2026-10-14",
               "monto": 69.99, "pendiente": 69.99, "moneda": "GTQ", "pagada": false,
               "url_pago": "https://.../my/invoices/3?access_token=..." }],
  "deuda": { "cuotas": 1, "monto": 69.99 }
}
```
La carencia de cada beneficiario cuenta desde que se agregó (supuesto D-17).

## Servicio Oro

| Ruta | Método | Auth | Qué hace |
|---|---|---|---|
| `/api/membresia/v1/servicios/evaluar?tipo=humano&beneficiario_id=5` | GET | Bearer | Candado para esa persona (sin crear nada): `{ok, permitido, mensaje, cargo, dias_restantes}` |
| `/api/membresia/v1/servicios` | POST | Bearer | Crea la solicitud si el candado lo permite: `201 {ok, servicio, mensaje}`; si no, `422 {ok: false, mensaje, candado}` |

Cuerpo de la solicitud:
```json
{
  "tipo": "humano",
  "beneficiario_id": 5,
  "mascota_id": null,
  "lugar": "Hospital General",
  "contacto_nombre": "Luis López",
  "contacto_telefono": "55554444",
  "notas": "",
  "dpi_foto": { "nombre_archivo": "dpi.jpg", "mime": "image/jpeg", "base64": "..." }
}
```
- `tipo`: `humano` (titular si no hay `beneficiario_id`) o `mascota` (con `mascota_id`).
- `dpi_foto` obligatoria para `humano`.
- `servicio`: `{id, numero, tipo, tipo_texto, persona, estado, estado_texto, fecha_solicitud,
  motivo_rechazo, cargo, url_pago}`. `url_pago` existe si hay un cargo pendiente (2.º servicio
  Q3,480 o mascota de más de 25 kg Q500).
- Los servicios del miembro también vienen en `membresia.servicios`.

## Seguridad

- Límite por IP: 10 afiliaciones por hora, 20 inicios de sesión cada 15 minutos, 5 recuperaciones
  por hora (`429`). Odoo además bloquea por IP tras varios intentos fallidos de contraseña.
- Sin CORS: la API la usa solo la app móvil.
- Afiliación: máximo 20 MB por petición.
- Las fotos de DPI solo las ve el grupo de documentos sensibles en Odoo.
