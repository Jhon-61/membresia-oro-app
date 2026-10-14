# CLAUDE.md · Membresía Oro · Las Golondrinas

App para vender y cobrar automáticamente la **Membresía Oro (Q69.99/mes por familia)**: cubre 5 personas
(titular + 4 beneficiarios) y 1 cremación de mascota de hasta 25 kg. Venta 100% directa; 1 administrador
debe manejar 1,000+ miembros. **El núcleo del negocio es la cobranza automática.** Móvil primero (90% celular).

Documentos de referencia (leer antes de cambiar reglas de negocio):
- `docs/CONTEXTO_MEMBRESIA_ORO.md`: brief técnico original (fuente de verdad del negocio; su parte de
  arquitectura con Firebase quedó reemplazada por Odoo, ver D-13).
- `docs/API_ODOO.md`: **contrato entre la app y Odoo**.
- `docs/DECISIONES.md`: decisiones tomadas y por qué.
- `docs/PREGUNTAS_ABIERTAS.md`: dudas pendientes. **No inventar respuestas**: si una tarea depende de una
  pregunta abierta, preguntar o dejarlo configurable.
- `docs/PLAN_DE_TRABAJO.md`: plan original de 6 semanas (pendiente de rehacer con la arquitectura Odoo).

## Sobre el desarrollador

- Desarrollador **solo**, está **aprendiendo Flutter/Dart y Odoo/Python** (empezó en oct 2026).
- **Responder, comentar y escribir commits en español.** Explicar el porqué, no solo el código.
- Preferir soluciones simples y legibles sobre abstracciones avanzadas.

## Arquitectura (D-13)

```
App Flutter (Android / iOS)  ──HTTPS JSON──→  Odoo 19 Enterprise en Odoo.sh
  solo la parte del cliente                     módulos membresia_oro + membresia_oro_documentos
                                                (miembros sobre Contactos, documentos, API, y luego
                                                 cobranza, contratos, WhatsApp, FEL)
```

- **Backend = Odoo.** Módulos en otro repositorio: `Jhon-61/pruebas` (rama `prueba`), copia local en
  `C:\Users\nder1\Music\chamba\modulos\proyectos+`.
- **Panel admin = el propio Odoo** (no hay panel en Flutter).
- Fuera de Odoo solo quedan: la app Flutter, Firebase para notificaciones push y quizá el login por SMS
  (aún no configurado), y el formulario de tarjeta de Cybersource.

## Reglas de oro (no negociables)

1. **Todo lo que toca dinero, estados o candados se decide en Odoo, nunca en la app.** La app solo
   muestra datos y envía solicitudes; Odoo vuelve a validar todo porque la app se puede manipular.
2. **Contrato estable**: si cambia un campo, cambiar a la vez `app/lib/models/afiliacion.dart`,
   `docs/API_ODOO.md` y el controlador de Odoo.
3. **Idempotencia en cobros**: un ID único por miembro y periodo; nunca cobrar dos veces aunque algo
   se reintente.
4. **Dinero en centavos enteros** (`6999`, no `69.99`) en cálculos de backend. Nunca `double` para montos.
5. **Fechas de negocio en `America/Guatemala`** (día de cobro, atrasos, carencias).
6. **Nunca guardar datos de tarjeta.** Solo tokens de la pasarela; la tarjeta se escribe en su formulario.
7. **Secretos fuera del repo**: llaves de Cybersource, WhatsApp, Apple (`.p8`), keystore de Android.
   Nunca commitearlos.
8. **Probar solo en ramas de desarrollo/staging de Odoo.sh**, con datos ficticios. Nunca en producción.

## Estructura del repositorio

```
membresia_oro/
├── CLAUDE.md
├── docs/                         Contexto, contrato con Odoo, decisiones, preguntas, plan
└── app/                          Proyecto Flutter
    ├── lib/
    │   ├── main.dart             Entrada de la app
    │   ├── core/                 Tema, constantes de pantalla, validadores, formato, config (ODOO_URL)
    │   ├── models/               Datos y JSON del contrato con Odoo (afiliacion.dart), enums de estados
    │   ├── services/             Comunicación con Odoo (interfaz + implementación real + simulada)
    │   └── features/afiliacion/  Formulario de afiliación en 4 pasos
    └── test/                     Pruebas (validadores, JSON del contrato, servicio de Odoo, pantallas)
```

## Convenciones

- **Nombres de dominio en español.** En el JSON con Odoo, campos en `snake_case` (`fecha_nacimiento`).
- Las validaciones de `app/lib/core/validadores.dart` son espejo de `membresia_oro/validaciones.py`
  (DPI, teléfono, NIT con dígito verificador de `base_vat`). Cambiar ambas a la vez.
- Antes de terminar una tarea: `flutter analyze` y `flutter test` en `app/`.

## Comandos (desde app/)

```bash
flutter run -d edge                                   # sin ODOO_URL: servicio SIMULADO (no envía nada)
flutter run --dart-define=ODOO_URL=https://<rama>.dev.odoo.com
flutter build apk --release --split-per-abi --dart-define=ODOO_URL=https://<rama>.dev.odoo.com
flutter analyze
flutter test
```

Notas de Odoo.sh: cada push a una rama de desarrollo crea una compilación nueva con **otra URL y base
vacía** (hay que reinstalar el módulo y recompilar la app con la nueva URL).

## Pendiente

- iOS: compilar con Codemagic cuando exista la cuenta de Apple Developer de la empresa (requiere D-U-N-S).
- Antes de producción: autenticación en el endpoint (token), límite de peticiones y CORS restringido.
