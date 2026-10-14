# Plan de trabajo

Actualizado el 14 oct 2026. Arquitectura: **app Flutter (cliente) + Odoo 19 en Odoo.sh (todo el
negocio)** — ver `DECISIONES.md` D-13. Repositorios: app `Jhon-61/membresia-oro-app`; módulos
`Jhon-61/pruebas` (rama `prueba`, staging en Odoo.sh).

## ✅ Hecho

- App: afiliación en 4 pasos (titular, fotos del DPI, beneficiarios, mascota, términos y firma),
  validaciones (DPI, teléfono, NIT con dígito verificador), icono con el logo, compilación en Codemagic.
- Odoo `membresia_oro`: miembros sobre Contactos, beneficiarios, mascotas, cliente existente →
  "Por revisar", API de afiliación, factura de la primera cuota, miembro **activo al pagar**,
  botón "Crear factura de la cuota" (con periodo AAAA-MM, sin cuotas duplicadas).
- Odoo `membresia_oro_documentos`: fotos del DPI, firma y mascota protegidas.
- Odoo `payment_cybersource`: proveedor de pago completo (pendiente de que el sandbox de
  Cybersource deje de responder 502). **Mientras tanto se usa el proveedor Demo de Odoo.**

## Fase B · Seguridad, inicio de sesión y "Mi membresía" ✅

- [x] Odoo: cuenta de portal por miembro (correo + contraseña), sesiones con token, "olvidé mi
      contraseña", límite de intentos por IP, sin CORS, tamaño máximo de las peticiones.
- [x] App: contraseña en la afiliación, pantalla de inicio de sesión, sesión guardada de forma segura,
      cerrar sesión.
- [x] App: pantalla **Mi membresía** (estado, carencias, cuotas y pago de pendientes, beneficiarios,
      mascota).
- [x] App: al volver del pago, la app se actualiza sola y avisa si quedó aprobado.

## Fase C · Cobranza mensual y candados ✅

- [x] Acción programada diaria: cuota del mes el día de cobro, cobro automático con la tarjeta
      guardada, reintentos los días 3, 7 y 15, mora al día 30, cancelación al día 60.
- [x] Reactivar membresía (reinicia la carencia).
- [x] Candados: carencia humano 90 días / mascota 30 días (y por beneficiario agregado después),
      1 servicio cada 365 días, bloqueo en mora o cancelado.

## Fase D · Servicio Oro ✅

- [x] Odoo: solicitudes de servicio con flujo del administrador (aprobar, rechazar con motivo, en
      proceso, finalizar con fecha y costo) y factura de Q3,480 por el 2.º servicio.
- [x] App: botón "Solicitar Servicio Oro", formulario e historial.

## Fase E · Contrato, datos, cuenta, tablero y FEL ✅

- [x] Contrato en PDF con la firma, descargable desde la app.
- [x] App: editar teléfono, dirección, NIT y beneficiarios.
- [x] App: eliminar cuenta (requisito de las tiendas).
- [x] App: pantalla de carga con el logo.
- [x] Odoo: tablero (activos, ingreso del mes, % mora, servicios, utilidad estimada).
- [x] Odoo: diario configurable para las cuotas (el que emite FEL en la empresa).
- [x] Odoo: Membresía Oro → Ajustes (día de cobro, mora, cancelación, candados, costos,
      responsable de servicios).

## Pendiente (fuera de estas fases)

- Cambiar Demo por Cybersource cuando su sandbox funcione; generar llaves nuevas.
- WhatsApp (plantillas de Meta).
- iPhone con Codemagic (cuenta de Apple Developer, requiere D-U-N-S).
- Texto legal definitivo y política de privacidad (cliente).
- Respuestas del cliente en `PREGUNTAS_ABIERTAS.md` (mientras tanto se usan los supuestos de D-17).
