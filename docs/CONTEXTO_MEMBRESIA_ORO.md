# Contexto del proyecto: App Membresía Oro · Las Golondrinas

> Documento de contexto para Claude Code. Resume el brief técnico v2.0 (29/09/2026) y las decisiones tomadas en la fase de análisis (12–13 oct 2026). Úsalo como base para crear el plan de trabajo y el `CLAUDE.md` del repositorio.

---

## 1. Objetivo del negocio

- Vender y cobrar automáticamente la **Membresía Oro: Q69.99/mes** por familia.
- Cubre **5 personas** (titular + 4 beneficiarios) y **1 cremación de mascota de hasta 25 kg**.
- Venta 100% directa, sin vendedores. **1 administrador** debe poder manejar **1,000+ miembros**.
- El núcleo del negocio es la **cobranza automática**.
- Móvil primero: el 90% de los clientes usará el celular.

## 2. Stack técnico (decidido)

| Capa | Tecnología |
|---|---|
| Apps | **Flutter + Dart**: Android, iOS, Web (PWA) y panel admin web, una sola base de código |
| Backend | **Firebase** (plan Blaze) |
| Pagos | **QPayPro** (Guatemala) |
| Mensajería | **WhatsApp Cloud API** (3 plantillas aprobadas por Meta) |
| PDF | Paquete `pdf` de Dart (reemplaza jsPDF del brief) |
| Firma | Paquete `signature` |
| Repositorio | GitHub privado |

Cambios respecto al brief original: se descarta Supabase / Next.js / Vercel. Se elimina `stripe_customer_id` (resto del brief anterior) y se reemplaza por campos de QPayPro.

### Servicios de Firebase

- **Authentication**: login de clientes (teléfono SMS o correo). Rol admin por *custom claim* `admin: true`.
- **Cloud Firestore**: base de datos en tiempo real + Security Rules (el cliente solo ve lo suyo; estados y pagos solo los escribe el backend).
- **Cloud Functions** (+ Cloud Scheduler):
  - Endpoint HTTPS del webhook de QPayPro.
  - Tareas programadas diarias: reintentos, mora, cancelación, avisos de WhatsApp.
  - Callable `puedeUsarBeneficio(miembroId, tipo)`.
  - Generación del contrato PDF.
  - Llamadas a QPayPro, WhatsApp Cloud API y correo a la funeraria.
- **Cloud Storage**: fotos de mascota, fotos de DPI, contratos PDF (con reglas de acceso).
- **Cloud Messaging (FCM)**: notificaciones push.
- **Hosting**: web y panel admin en el dominio del cliente.
- **App Check** y **Crashlytics**: seguridad y monitoreo.

Regla de oro: **todo lo que toca dinero, estados o candados se decide en Cloud Functions, nunca en el cliente.**

## 3. Roles

- **Cliente**: se afilia solo, ve su membresía, beneficiarios y mascota, paga, solicita el Servicio Oro, ve su historial.
- **Admin**: ve todo, cobra (links / efectivo), aprueba servicios, ve KPIs, exporta reportes, reactiva miembros.

## 4. Módulos funcionales

### M1 · Landing + afiliación (2 minutos)
- Formulario: titular (nombre, DPI, teléfono, email, dirección), 4 beneficiarios (nombre, DPI, parentesco, fecha de nacimiento), 1 mascota (nombre, especie, raza, peso, foto).
- Mascota > 25 kg: **alerta "paga Q500 extra", no bloquear**.
- Aceptar términos + **firma con el dedo**.
- Cobro inmediato de Q69.99 con QPayPro (checkout alojado; la tarjeta nunca pasa por la app).
- Pago aprobado → crear usuario, generar **PDF Contrato Oro** (plantilla legal la da el cliente), enviarlo por WhatsApp, guardar token.
- Pago rechazado → miembro en estado pendiente + **link de pago por WhatsApp**.

### M2 · Cobranza automática (core)
- Tarjeta tokenizada en el primer cobro.
- **Día 1 de cada mes**: cobrar Q69.99 a todos los activos.
- Si falla: reintentos **día 3, 7 y 15**, cada uno con WhatsApp:
  - Día 3: "Hola {nombre}, tu Membresía Oro está pendiente Q69.99 {link}"
  - Día 15: "Tu membresía Oro entra en suspensión en 15 días. Paga aquí {link}"
- **Día 30** → estado `mora`, beneficio bloqueado.
- **Día 60** → estado `cancelado`, pierde carencia.
- Semáforo del dashboard: verde al día, amarillo 1–29 días, rojo 30–60, negro cancelado.
- Botones admin: "Enviar link de cobro", "Marcar pagado en efectivo", "Reactivar (reinicia carencia)".
- **Idempotencia obligatoria**: un `cobroId` único por miembro y mes; nunca cobrar dos veces si la función se reintenta.

### M3 · Candados Oro
- `fecha_activacion_humano = fecha_alta + 90 días`; `fecha_activacion_mascota = fecha_alta + 30 días`.
- `puedeUsarBeneficio(miembroId, tipo)` → `{ permitido: bool, mensaje: "Te faltan 23 días" }`.
- 1 servicio cada **365 días** desde `ultimo_servicio_fecha`.
- 2º servicio antes de 365 días: **40% de descuento sobre Q5,800 → paga Q3,480**; generar link de pago por esa cantidad.
- Miembro en mora o cancelado: no puede usar el beneficio.

### M4 · Botón Servicio Oro
- Botón grande rojo "Solicitar Servicio Oro".
- Formulario: tipo (humano/mascota), quién (select de sus 5 + 1), lugar del fallecimiento, contacto, foto DPI.
- Al enviar: ticket en `servicios` con estado `pendiente` + WhatsApp al admin + email a la funeraria + push.
- Admin: aprobar, rechazar (con motivo), marcar en proceso, finalizar (fecha y costo real).
- Historial visible para el cliente.

### M5 · Panel admin
- KPIs: total activos, ingreso del mes, % mora, servicios del mes, **utilidad estimada = ingreso − (servicios × Q5,800 + mascotas × Q700) − pasarela**.
- Tabla de miembros con filtros: DPI, teléfono, estado, fecha de alta.
- Exportar CSV: miembros, pagos del mes, servicios del mes.
- **Fase 2** (fuera del MVP): proyección de utilidad 12 meses y gráfica ingreso vs. costo de siniestralidad.
- Usar **contadores agregados** mantenidos por Functions (Firestore no tiene joins; evita lecturas masivas).

## 5. Modelo de datos (Firestore, adaptado del brief)

```
miembros/{miembroId}
  uid, titularNombre, dpi, telefono, email, direccion,
  fechaAlta, fechaActivacionHumano, fechaActivacionMascota,
  estado: 'pendiente'|'activo'|'mora'|'suspendido'|'cancelado',
  diasAtraso, ultimoServicioFecha,
  qpayCustomerId, qpayTokenId | qpaySubscriptionId,
  firmaUrl, contratoUrl, creadoEn, actualizadoEn
  /beneficiarios/{id}: nombre, dpi, parentesco, fechaNac
  /mascotas/{id}: nombre, especie, raza, pesoKg, fotoUrl, cargoExtra (bool)

pagos/{pagoId}
  miembroId, monto, periodo ('2026-11'), cobroId (idempotencia),
  fechaCobro, fechaPagada, intento (1-4),
  estado: 'pagado'|'fallido'|'pendiente',
  metodo: 'tarjeta'|'link'|'efectivo'|'deposito',
  qpayTransactionId, linkPago

servicios/{servicioId}
  miembroId, tipo: 'humano'|'mascota', beneficiarioId | mascotaId,
  fechaSolicitud, fechaAtencion, lugar, contacto, dpiFotoUrl,
  estado: 'pendiente'|'aprobado'|'en_proceso'|'rechazado'|'finalizado',
  motivoRechazo, costoReal, montoDiferencia

webhookEventos/{eventId}   // para idempotencia del webhook
stats/{periodo}            // contadores agregados para KPIs
```

Nota: el ENUM de `servicios` del brief no incluía `en_proceso`, aunque el admin puede marcarlo; se agregó.

## 6. QPayPro (investigado 12 oct 2026, confirmar con el proveedor)

- Pasarela guatemalteca, PCI DSS nivel 1. Docs: https://developers.qpaypro.com · KB: https://qpaypro.zohodesk.com/portal/es/kb/payments
- Tiene **sandbox**, **webhooks firmados** con reintentos (eventos de cobro y de suscripción: creada, cobro exitoso, cobro fallido, próximo cobro, cancelada).
- Dos rutas para cobro recurrente:
  - **A · QPayBilling (recomendada)**: QPayPro maneja planes y cobro mensual; la app reacciona a webhooks.
  - **B · QPayToken**: crear cliente → asociar tarjeta → token; Cloud Functions cobra con el token. Endpoint sandbox de pago por token: `https://sandbox.qpaypro.com/integraciones/api-tokenizations/process_payment_token_validations.php`. Según la KB requiere plan Enterprise.
- Implementar una interfaz `PaymentProvider` para poder cambiar de ruta (o de proveedor) sin reescribir.
- Precios publicados: Free 5.95% + Q2.95; Premium (Q195/mes) y Elite (Q395/mes) desde 3.5% + Q2.95; Enterprise Q5,000/mes. Efectivo y depósito: 0%. Cobros fallidos no pagan comisión.
- Con 3.5% + Q2.95, de cada Q69.99 llegan **Q64.59** (sin contar IVA de comisión ni retención de IVA).
- Liquidación: 3 cortes por semana, 24–48 h hábiles.

### Preguntas abiertas a QPayPro
1. ¿QPayBilling permite reintentos configurables (días 3, 7, 15) y suspensión al día 30?
2. ¿Qué plan incluye suscripciones y tokenización? (contradicción: tabla de precios dice Premium/Elite, KB dice Enterprise).
3. ¿Aprueban el giro "membresías / servicios funerarios"? ¿Banda MCC y tarifa?
4. ¿Cómo se valida la firma del webhook? ¿Política exacta de reintentos?
5. ¿Se puede cobrar un monto puntual distinto (Q3,480) o solo por link?
6. ¿Actualización de tarjetas vencidas?
7. ¿QPayFel puede emitir la factura FEL de cada cobro?
8. Credenciales de sandbox desde ya.

## 7. Publicación en tiendas

- Cuentas a nombre de **Las Golondrinas (organización)**, con número **D-U-N-S** (tramitar desde el día 1).
- Google Play: USD 25 una vez, archivo `.aab`. Las cuentas personales nuevas requieren 12 testers × 14 días; las de organización no.
- App Store: USD 99/año, requiere Mac o CI en la nube (Codemagic / GitHub Actions macOS), TestFlight antes de revisión.
- Obligatorio en ambas: política de privacidad, formulario de datos, opción de **eliminar cuenta**, cuenta de prueba para el revisor.
- Pagos con QPayPro permitidos porque se pagan **servicios físicos**, no contenido digital; explicarlo en notas al revisor.

## 8. Pendientes que no dependen del desarrollo

- Factura electrónica **FEL** por cada cobro (no estaba en el brief, es obligatoria).
- Aprobación de las 3 plantillas de WhatsApp en Meta (iniciar el día 1).
- Revisión legal del contrato y de si la membresía requiere algún registro.
- Plantilla del texto legal del contrato (la entrega el cliente).

## 9. Entregables (brief)

Código en GitHub privado, APK Android (más publicación en tiendas si se acuerda), web en el dominio del cliente, manual de 2 páginas, 30 días de soporte de errores.

## 10. Plan y estimación

- Plazo del brief: 21 días calendario desde el anticipo (muy ajustado; considerar 4–5 semanas).
- Propuesta de fases:
  - **Semana 1**: proyecto Flutter + Firebase, auth y roles, afiliación con firma y PDF, sandbox QPayPro, envío de plantillas WhatsApp.
  - **Semana 2**: cobro mensual, webhooks, reintentos y estados de mora, WhatsApp automático, candados Oro.
  - **Semana 3**: Servicio Oro, panel admin + KPIs + CSV, pruebas completas en sandbox, publicación.
  - **Fase 2**: proyección de utilidad 12 meses, gráfica ingreso vs. costo.
- Estimación: **~226 horas** (setup 16, diseño 16, afiliación 24, QPayPro 32, cobranza 24, WhatsApp 12, PDF 10, candados + servicio 20, panel admin 32, seguridad + QA 24, publicación 16).

## 11. Diseño

- Colores: azul oscuro `#0A1931`, dorado `#D4AF37`, blanco.
- Logo: "MEMBRESÍA ORO · LAS GOLONDRINAS".
- Móvil primero.

## 12. Restricciones del cliente

- Nada de WordPress.
- Nada de licencias mensuales caras.
