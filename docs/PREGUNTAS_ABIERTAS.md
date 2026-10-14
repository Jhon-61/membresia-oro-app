# Preguntas abiertas

Marcar con ✅ y la respuesta cuando se resuelvan; pasar a `DECISIONES.md` si generan una decisión.

## Para el cliente (reglas de negocio)

- [ ] **P-01 · Estado `suspendido`**: el mensaje del día 15 dice "entra en suspensión en 15 días", pero el
      día 30 el estado pasa a `mora`. ¿Suspendido y mora son lo mismo? Definir el diagrama de estados exacto.
- [ ] **P-02 · Día de cobro**: ¿se cobra el día 1 a todos o en la fecha de aniversario? Si alguien se
      afilia el 25, ¿se le cobra completo el día 1 siguiente? ¿Hay prorrateo?
- [ ] **P-03 · Límite de 365 días**: ¿es compartido entre servicio humano y mascota, o va por tipo?
- [ ] **P-04 · 2º servicio de mascota**: ¿también aplica 40% de descuento? ¿Sobre qué monto?
- [ ] **P-05 · Mascota de más de 25 kg**: ¿cuándo y cómo se cobran los Q500 extra (al afiliarse o al usar el servicio)?
- [ ] **P-06 · Cambio de beneficiarios**: ¿se permite? ¿La carencia de 90 días se reinicia para el
      beneficiario nuevo? (Propuesta: carencia por beneficiario, para evitar fraude.)
- [ ] **P-07 · Requisitos de beneficiarios**: ¿límite de edad? ¿exclusiones (preexistencias)?
- [ ] **P-08 · Eliminar cuenta**: ¿qué datos se conservan por obligación legal (contrato, pagos, facturas)?
- [ ] **P-09 · Texto legal** del contrato y política de privacidad: ¿cuándo se entregan?
- [ ] **P-10 · Dominio** y acceso al DNS.
- [ ] **P-11 · Correo de la funeraria** que recibe las solicitudes de servicio.

- [ ] **P-12 · Datos para la factura**: ¿se pide NIT en la afiliación o se factura a "CF" con el DPI?
      (Necesario para Odoo/FEL; agregaría un campo al formulario.)
- [ ] **P-13 · Pasarela de producción**: ¿Cybersource (con qué banco) o QPayPro? ¿Las Golondrinas ya
      tiene afiliación de comercio electrónico con algún banco?

## Para el banco / Cybersource (producción)

- [ ] **C-01** ¿Qué banco adquirente nos da la cuenta de Cybersource? ¿Aprueban el giro funerario con
      cobro recurrente? ¿Comisión y requisitos (depósito de garantía, retención)?
- [ ] **C-02** ¿Habilitan **Token Management Service (TMS)** para guardar tarjetas y cobrar cada mes?
- [ ] **C-03** ¿Habilitan **Unified Checkout** (o Secure Acceptance) para la página de pago alojada?
- [ ] **C-04** ¿Habilitan **webhooks** de Cybersource? ¿Cómo se valida la firma?
- [ ] **C-05** ¿Se exige 3-D Secure? ¿Cómo aplica a los cobros recurrentes con token?
- [ ] **C-06** ¿Cómo y cuándo liquidan los fondos? ¿El depósito llega neto de comisión? (Para Odoo.)

## Para QPayPro (en pausa por D-10)

- [ ] **Q-01** ¿Aprueban el giro "membresías / servicios funerarios"? ¿Banda MCC y tarifa?
- [ ] **Q-02** ¿Qué plan incluye suscripciones (QPayBilling) y tokenización (QPayToken)? La tabla de
      precios dice Premium/Elite y la KB dice Enterprise.
- [ ] **Q-03** ¿QPayBilling permite reintentos configurables (días 3, 7, 15) y suspensión al día 30?
- [ ] **Q-04** ¿Cómo se valida la firma del webhook? ¿Política exacta de reintentos?
- [ ] **Q-05** ¿Se puede cobrar un monto puntual distinto (Q3,480) con token, o solo por link?
- [ ] **Q-06** ¿Cómo se actualizan las tarjetas vencidas?
- [ ] **Q-07** ¿QPayFel puede emitir la factura FEL de cada cobro automáticamente?
- [ ] **Q-08** Credenciales de sandbox.
- [ ] **Q-09** ¿Los links de pago expiran? ¿Se puede pasar una referencia propia (`cobroId`) y recibirla en el webhook?

## Para Meta / WhatsApp

- [ ] **W-01** Verificación del negocio y número dedicado.
- [ ] **W-02** Aprobación de plantillas (al menos 4): bienvenida + contrato, pago pendiente con link,
      aviso del día 15, aviso al admin de solicitud de servicio.
- [ ] **W-03** Costo por mensaje de plantilla en Guatemala (para la fórmula de utilidad).

## Odoo (contabilidad)

- [ ] **O-01** ¿Qué versión de Odoo (17, 18, 19)? ¿Community o Enterprise?
- [ ] **O-02** ¿Dónde está alojado: Odoo Online, Odoo.sh o servidor propio? Si es servidor propio,
      ¿es accesible desde internet por HTTPS?
- [ ] **O-03** Si es Odoo Online: ¿el plan incluye API externa? (Solo el plan Custom la incluye.)
- [ ] **O-04** ¿El Odoo ya emite **FEL**? ¿Con qué módulo y certificador?
- [ ] **O-05** ¿Cómo quiere el contador cada cobro: factura + pago por cada mensualidad? ¿Qué diarios
      (pasarela, efectivo, depósito)? ¿Qué cuentas contables y productos?
- [ ] **O-06** ¿Cómo registrar la comisión de la pasarela? ¿Al liquidar (conciliación bancaria)?
- [ ] **O-07** Pagos en efectivo: ¿se registran en la app (y la app los manda a Odoo) o en Odoo?
- [ ] **O-08** ¿Los costos de servicios (Q5,800 / Q700) también deben ir a Odoo, o ya los maneja operaciones?
- [ ] **O-09** ¿Hay una **base de datos de prueba** de Odoo para la integración? ¿Quién es el contacto contable?

## FEL

- [ ] **F-01** ¿Lo emite Odoo (ver O-04) o se necesita un certificador aparte (Infile, Digifact, etc.)?
