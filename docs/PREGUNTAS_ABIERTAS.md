# Preguntas abiertas

Marcar con ✅ y la respuesta cuando se resuelvan; pasar a `DECISIONES.md` si generan una decisión.
Mientras no haya respuesta, el sistema usa los **supuestos de D-17** (configurables).

## Para el cliente (reglas de negocio)

- [ ] **P-01 · Estado `suspendido`**: el mensaje del día 15 dice "entra en suspensión en 15 días", pero el
      día 30 el estado pasa a `mora`. ¿Suspendido y mora son lo mismo? *Supuesto: el día 30 pasa a mora.*
- [ ] **P-02 · Día de cobro**: ¿se cobra el día 1 a todos o en la fecha de aniversario? Si alguien se
      afilia el 25, ¿se le cobra completo el día 1 siguiente? *Supuesto: día 1, sin prorrateo.*
- [ ] **P-03 · Límite de 365 días**: ¿es compartido entre servicio humano y mascota, o va por tipo?
      *Supuesto: compartido (un solo "último servicio", como en el brief).*
- [ ] **P-04 · 2º servicio de mascota**: ¿también aplica 40% de descuento? *Supuesto: no está cubierto.*
- [ ] **P-05 · Mascota de más de 25 kg**: ¿cuándo se cobran los Q500 extra? *Supuesto: al pedir el servicio.*
- [ ] **P-06 · Cambio de beneficiarios**: ¿la carencia de 90 días se reinicia para el beneficiario nuevo?
      *Supuesto: sí, carencia por beneficiario (evita fraude).*
- [ ] **P-07 · Requisitos de beneficiarios**: ¿límite de edad? ¿exclusiones (preexistencias)?
- [ ] **P-08 · Eliminar cuenta**: ¿qué datos se conservan por obligación legal? *Supuesto: se conservan
      contrato y facturas; se borran fotos del DPI y firma; la membresía se cancela.*
- [ ] **P-09 · Texto legal** del contrato y política de privacidad.
- [ ] **P-10 · Dominio** y acceso al DNS.
- [ ] **P-11 · Correo de la funeraria** que recibe las solicitudes de servicio.
- [ ] **P-12 · ¿El precio de Q69.99 incluye IVA?** (Para configurar el impuesto del producto.)
- [ ] **P-13 · Carencia**: ¿cuenta desde la afiliación o desde el primer pago? *Supuesto: desde la afiliación.*
- [ ] **P-14 · Logo original** en alta resolución (para el icono de la App Store).

## Para NeoNet / Cybersource (producción)

- [ ] **C-01** Comercio de **pruebas** y de **producción** para Las Golondrinas. ¿Aprueban el giro
      funerario con cobro recurrente? ¿Comisión y requisitos?
- [ ] **C-02** Habilitar **Token Management Service (TMS)** para cobrar cada mes con la tarjeta guardada.
- [ ] **C-03** Habilitar **Unified Checkout** (en el comercio de producción no aparece).
- [ ] **C-04** ¿Se exige 3-D Secure? ¿Cómo aplica a los cobros recurrentes con token?
- [ ] **C-05** ¿Cuándo liquidan los fondos? ¿El depósito llega neto de comisión?
- [ ] **C-06** Sandbox `golondrinas_p_1792005315`: todos los cobros responden 502 "General system failure"
      (también desde la Live Console). Pedir revisión al soporte de Cybersource.

## Para Meta / WhatsApp (pendiente)

- [ ] **W-01** Verificación del negocio y número dedicado.
- [ ] **W-02** Plantillas: bienvenida + contrato, pago pendiente con link, aviso de mora, aviso al admin.

## Contabilidad y FEL

- [ ] **O-01** ¿Qué módulo y certificador de **FEL** usa la empresa en Odoo? ¿Qué **diario** emite FEL?
- [ ] **O-02** ¿Cómo registrar la comisión de la pasarela? ¿Al conciliar el depósito?
- [ ] **O-03** Pagos en efectivo: ¿se registran directo en Odoo? (Supuesto: sí, con "Registrar pago".)
