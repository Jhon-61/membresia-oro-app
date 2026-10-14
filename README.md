# Membresía Oro · App

App de afiliación de la **Membresía Oro** de Las Golondrinas (Android, iOS), hecha en Flutter.
El backend es **Odoo 19** (módulos `membresia_oro` y `membresia_oro_documentos`).

## Ejecutar

Desde la carpeta `app/`:

```bash
flutter pub get
flutter run                       # modo simulado: no envía datos
flutter run --dart-define=ODOO_URL=https://<tu-odoo>
```

## Compilar para Android

```bash
flutter build apk --release --split-per-abi --dart-define=ODOO_URL=https://<tu-odoo>
```

## Documentación

- `docs/API_ODOO.md`: contrato entre la app y Odoo.
- `docs/DECISIONES.md`: decisiones de arquitectura.
- `docs/PREGUNTAS_ABIERTAS.md`: pendientes con el cliente.
