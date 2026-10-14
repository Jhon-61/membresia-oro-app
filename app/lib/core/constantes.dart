// Constantes SOLO para mostrar en pantalla.
// Las reglas reales (cobros, estados, candados) las decide el backend (Odoo):
// la app nunca toma decisiones de negocio con estos valores.

const String cuotaMensualTexto = 'Q69.99';
const int maxBeneficiarios = 4;
const int pesoMaxMascotaKg = 25;
const String cargoExtraMascotaTexto = 'Q500';
const int carenciaHumanoDias = 90;
const int carenciaMascotaDias = 30;

/// Versión del texto de términos que acepta el cliente. Se envía a Odoo para saber
/// qué versión firmó cada miembro. Cambiarla cuando llegue el texto legal definitivo.
const String versionTerminos = 'borrador-2026-10';
