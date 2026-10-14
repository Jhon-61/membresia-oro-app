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
    "nit": "CF"
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
  "url_pago": "https://<odoo>/my/invoices/45?access_token=..."
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

## Seguridad: pendiente antes de producción

En la fase de pruebas el endpoint es público (`auth="public"`) para poder probar rápido en la rama de
desarrollo de Odoo.sh. **Antes de producción**:

1. **Autenticación**: la app enviará `Authorization: Bearer <token de Firebase>` (login por SMS) y Odoo
   verificará el token antes de crear nada.
2. **Límite de peticiones** por IP/teléfono, para evitar que llenen la base con solicitudes falsas.
3. **CORS** solo si se usa la versión web de Flutter: permitir únicamente el dominio de la app.
   (Las apps de Android/iOS no necesitan CORS.)
4. Las fotos de DPI solo visibles para el grupo de administradores.
