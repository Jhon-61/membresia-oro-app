# Registro de decisiones

Cada decisión con fecha, qué se decidió y por qué. Si una decisión cambia, no se borra: se marca como
reemplazada y se agrega la nueva.

---

### D-01 · Plazo de 6 semanas (13 oct 2026)
**Decisión:** alcance completo en 6 semanas + semana 0 de arranque, en lugar de 21 días.
**Por qué:** la estimación corregida es de 290–320 h (el brief decía 226 h sin contar FEL, landing,
ambientes, auditoría, eliminación de cuenta ni curva de aprendizaje). Un solo desarrollador.
**Nota:** aún no hay anticipo ni fecha firmada; las fechas del plan son tentativas.

### D-02 · Desarrollador único, sin Mac por ahora (13 oct 2026)
**Decisión:** desarrollar y probar en Android y Web. iOS se compila después con Codemagic (CI en la nube)
o una Mac prestada, cuando exista la cuenta de Apple de organización (requiere D-U-N-S).

### D-03 · Cobranza: primero link de pago, después cobro automático (13 oct 2026) · *actualizada por D-10*
**Decisión:** construir toda la cobranza (estados, reintentos, mora, WhatsApp, semáforo) sobre
**links de pago**. El cobro automático (QPayBilling o QPayToken) se conecta después detrás de
`PaymentProvider`, cuando QPayPro confirme plan, costo y giro.
**Por qué:** el link se necesita de todas formas (reintentos, pago rechazado, 2º servicio de Q3,480,
clientes sin tarjeta guardada); no bloquea el desarrollo esperando a QPayPro; la tokenización podría
requerir plan Enterprise (Q5,000/mes), que choca con la restricción de "nada de licencias caras".

### D-04 · Cloud Functions en TypeScript (13 oct 2026)
**Decisión:** Functions en TypeScript (Node 22).
**Por qué:** es la opción estándar, mejor documentada y con más ejemplos para Firebase.

### D-05 · Contrato PDF generado en el servidor (13 oct 2026)
**Decisión:** el PDF se genera en Cloud Functions con `pdf-lib` (reemplaza "paquete `pdf` de Dart").
**Por qué:** un documento legal generado en el dispositivo del cliente podría alterarse.

### D-06 · Landing en HTML estático (13 oct 2026)
**Decisión:** la landing de ventas es HTML/CSS liviano en Firebase Hosting; el botón "Afíliate" abre la
app Flutter Web.
**Por qué:** Flutter Web carga ~2 MB y casi no lo indexa Google; la landing es la puerta de venta directa.

### D-07 · Panel admin como entrada separada (13 oct 2026)
**Decisión:** `app/lib/main_admin.dart`, mismo proyecto Flutter, desplegado solo en web.
**Por qué:** el código del admin no viaja dentro de la app del cliente; se comparten modelos y tema.

### D-08 · El cliente solo lee; las escrituras importantes pasan por Functions (13 oct 2026) · *propuesta*
**Decisión:** en Firestore, el cliente puede **leer** sus documentos (`miembros`, `beneficiarios`,
`mascotas`, `pagos`, `servicios`), pero la afiliación, solicitudes de servicio y cambios de datos se
hacen llamando a Cloud Functions (callables) que validan y escriben.
**Por qué:** aplica la regla de oro con reglas de seguridad simples y difíciles de equivocar.
Revisar en Sprint 1 si algún campo no sensible (p. ej. dirección) conviene editarlo directo.

### D-10 · Cybersource como pasarela de pruebas (13 oct 2026)
**Decisión:** el desarrollo y las pruebas de pagos se hacen con el **sandbox de Cybersource**
(`apitest.cybersource.com`). QPayPro queda en pausa. La pasarela de **producción está por confirmar**
(Cybersource a través del banco adquirente del cliente, o QPayPro); por eso todo pasa por `PaymentProvider`.
**Cómo encaja con D-03:** el "link de pago" pasa a ser una **página de pago propia**
(p. ej. `/pagar/{cobroId}`) que carga **Unified Checkout** de Cybersource. La tarjeta se escribe en el
widget de Cybersource (nunca toca la app ni Firebase); Functions recibe un token temporal, autoriza el
cobro y, si el miembro acepta, crea un token permanente en **TMS** para los cobros mensuales automáticos.
La misma página sirve para afiliación, reintentos, 2º servicio (Q3,480) y cargo de mascota.
**Ojo:** en el sandbox todo viene habilitado; en producción, TMS y Unified Checkout los habilita
Cybersource o el banco. Confirmar antes de depender de ellos (ver PREGUNTAS C-01 a C-05).

### D-11 · Firebase de desarrollo en la cuenta propia del desarrollador (13 oct 2026)
**Decisión:** el proyecto `membresia-oro-dev` se crea en la cuenta de Google del desarrollador.
`membresia-oro-prod` se crea en la cuenta de Las Golondrinas, con su facturación.
**Regla:** en `dev` solo datos **ficticios** (nada de DPI, fotos ni teléfonos reales de clientes).

### D-12 · Integración con Odoo para la contabilidad (13 oct 2026) · *diseño propuesto*
**Decisión:** la app envía a Odoo cada movimiento contable; **un solo sentido: App → Odoo**.
- Cada miembro → contacto (`res.partner`), identificado por DPI/NIT.
- Cada pago aprobado → factura de cliente (`account.move`) + pago registrado en el diario que corresponda
  (pasarela, efectivo, depósito). La factura lleva el `cobroId` como referencia para no duplicarla.
- Si el Odoo del cliente ya emite **FEL**, la factura se certifica desde Odoo y la app **no** integra
  FEL por separado (reemplaza la tarea de FEL del plan).
**Reglas:**
- La sincronización es **asíncrona y con reintentos**: si Odoo está caído, el cobro y el estado del
  miembro siguen normal; el pago queda con `odooEstado: 'pendiente'` y se reintenta.
- La app es la fuente de verdad de membresías y estados; Odoo es la fuente de verdad contable.
  Odoo nunca activa ni bloquea miembros.
- Usuario de integración en Odoo con permisos mínimos y API key en Secret Manager.
- Pruebas solo contra una **base de datos de prueba** de Odoo, nunca la contabilidad real.
**Pendiente:** versión, hosting y plan de Odoo (ver PREGUNTAS O-01 a O-09). En Odoo Online la API
externa solo está disponible en el plan Custom.

### D-13 · Odoo como backend completo (14 oct 2026) · *reemplaza la parte de Firebase de D-04 a D-08, D-11 y D-12*
**Decisión:** la empresa usa **Odoo 19 Enterprise en Odoo.sh** y acepta módulos personalizados. Todo el
negocio vive en Odoo (módulos `membresia_oro` y `membresia_oro_documentos`): miembros sobre Contactos,
beneficiarios, mascotas, documentos, y después cobranza, contrato PDF, WhatsApp y FEL. El panel admin es
el propio Odoo. La app Flutter queda solo para el cliente y se comunica con Odoo por HTTPS
(`docs/API_ODOO.md`). Se eliminaron del repositorio `functions/`, las reglas de Firestore/Storage y el
panel admin en Flutter.
**Por qué:** el equipo ya trabaja en Odoo; se evita sincronizar dos bases de datos; contabilidad y FEL
ya están ahí; se ahorra programar el panel admin.
**Fuera de Odoo:** la app (Android/iOS), Firebase para push y quizá login por SMS, y el formulario de
tarjeta de Cybersource.

### D-14 · Clientes que ya existen en Odoo (14 oct 2026)
**Decisión:** al afiliarse se busca a la persona por DPI → correo → teléfono. Si ya es cliente, se le
agrega la membresía sin cambiar sus datos (solo se completan los vacíos), la app muestra un aviso y en
Odoo queda "Por revisar". Si varios coinciden, se crea uno nuevo para revisar. Más seguridad después.

### D-09 · Montos en centavos y fechas en hora de Guatemala (13 oct 2026)
**Decisión:** montos como enteros en centavos; cálculos de fechas en `America/Guatemala`.
**Por qué:** los `double` generan errores de redondeo con dinero; en UTC el "día 1" empezaría el día 30
a las 6 p. m. hora local.
