# Plan de trabajo · 6 semanas

> ⚠️ **Desactualizado (14 oct 2026):** este plan es de la arquitectura con Firebase. Con Odoo como backend
> (D-13), las tareas de Functions, Firestore y panel admin se reemplazan por módulos de Odoo. Pendiente
> de rehacer. Avance real: formulario de afiliación en la app + módulos `membresia_oro` y
> `membresia_oro_documentos` funcionando en Odoo.sh (rama `prueba`).

Fechas tentativas: no hay anticipo ni fecha firmada (ver `DECISIONES.md` D-01).
Supone inicio de Sprint 1 el lunes 19 oct 2026. Cada sprint termina con una **demo al cliente**.

## Semana 0 · Arranque (13–16 oct)

### Trámites externos (iniciar ya, tardan semanas)
- [ ] D-U-N-S de Las Golondrinas (cliente)
- [ ] Meta Business: verificación del negocio + número dedicado de WhatsApp
- [ ] Crear cuenta de **sandbox de Cybersource** y generar llaves de API (D-10)
- [ ] Preguntar al banco / Cybersource: C-01 a C-06
- [ ] Preguntar sobre Odoo: O-01 a O-09 (y conseguir base de datos de prueba)
- [ ] Enviar al cliente las preguntas P-01 a P-13
- [ ] Cuenta de Google Play de organización (USD 25), cuando haya D-U-N-S

### Técnico
- [x] Estructura del repositorio, `CLAUDE.md`, documentos
- [ ] Repositorio privado en GitHub + primer commit
- [ ] Instalar Firebase CLI (`npm install -g firebase-tools`) y `firebase login`
- [ ] Crear `membresia-oro-dev` en tu cuenta de Firebase (plan Blaze, alerta de presupuesto) (D-11)
- [ ] `membresia-oro-prod` en la cuenta del cliente (puede esperar hasta Sprint 4)
- [ ] `flutterfire configure` para ambos ambientes
- [ ] Probar emuladores locales (`firebase emulators:start`)
- [ ] Bocetos de pantallas principales (azul `#0A1931`, dorado `#D4AF37`)
- [ ] Aprendizaje: TypeScript básico, Firestore, Security Rules

## Sprint 1 · Base + afiliación (semanas 1–2: 19–30 oct)
- [ ] Login (teléfono SMS o correo) y custom claim `admin`
- [ ] Modelos Dart + enums; colecciones y Security Rules con pruebas en emulador
- [ ] Formulario de afiliación: titular (+ NIT o CF, según P-12), 4 beneficiarios, mascota (alerta > 25 kg sin bloquear)
- [ ] Términos + firma con el dedo; fotos a Storage
- [ ] Callable `iniciarAfiliacion` (valida y crea miembro en `pendiente`)
- [ ] Contrato PDF en Functions con plantilla temporal
- [ ] Landing HTML
- [ ] **Demo:** afiliarse de punta a punta con pago simulado

## Sprint 2 · Cobranza (semanas 3–4: 2–13 nov)
- [ ] `PaymentProvider` + implementación Cybersource (sandbox)
- [ ] Página de pago propia `/pagar/{cobroId}` con Unified Checkout (D-10)
- [ ] Guardar tarjeta con TMS y cobro mensual con token
- [ ] Webhook HTTPS idempotente (`webhookEventos`) con validación de firma
- [ ] Primer cobro al afiliarse → `activo`, contrato por WhatsApp
- [ ] Tarea diaria (Cloud Scheduler, hora de Guatemala): cobro día 1, reintentos 3/7/15, mora 30, cancelado 60
- [ ] `pagos` con `cobroId` = `{miembroId}_{AAAA-MM}`
- [ ] WhatsApp automático con plantillas
- [ ] Cliente de Odoo en Functions + sincronización asíncrona: contacto, factura y pago por cada cobro (D-12)
- [ ] FEL: desde Odoo si ya lo emite (O-04); si no, integración aparte (+1 semana)
- [ ] Pruebas unitarias de la máquina de estados con fechas simuladas
- [ ] **Demo:** simular un mes completo de cobranza

## Sprint 3 · Candados, Servicio Oro y panel admin (semana 5: 16–20 nov)
- [ ] Callable `puedeUsarBeneficio` (carencias 90/30 días, 365 días, mora/cancelado) + pruebas
- [ ] Botón "Solicitar Servicio Oro" + formulario + ticket + WhatsApp admin + correo funeraria + push
- [ ] Flujo admin: aprobar / rechazar con motivo / en proceso / finalizar; link de Q3,480 para 2º servicio
- [ ] Panel: semáforo, tabla con filtros, botones de cobro/efectivo/reactivar, KPIs desde `stats`, CSV
- [ ] Colección `auditoria`
- [ ] Panel: pagos con error de sincronización a Odoo + botón "reintentar"; reporte de conciliación mensual
- [ ] **Demo:** el admin maneja un caso completo

## Sprint 4 · Calidad y lanzamiento (semana 6: 23–27 nov)
- [ ] Revisión de seguridad (rules, App Check, secretos)
- [ ] Eliminar cuenta, política de privacidad, formulario de datos de las tiendas
- [ ] Pruebas completas en sandbox + dispositivos Android reales
- [ ] Piloto con 10–20 miembros reales
- [ ] Publicar web en el dominio del cliente + Android (`.aab`) en Play Store
- [ ] Manual de 2 páginas

## Después del lanzamiento
- [ ] iOS: Codemagic o Mac, TestFlight y revisión de Apple
- [ ] Cobro automático (QPayBilling o QPayToken) detrás de `PaymentProvider`
- [ ] 30 días de soporte de errores
- [ ] Fase 2: proyección de utilidad 12 meses, gráfica ingreso vs. siniestralidad
