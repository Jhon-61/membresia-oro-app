import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../core/constantes.dart';
import '../../core/validadores.dart';
import '../../models/afiliacion.dart';

/// Datos de un beneficiario mientras se llena el formulario.
class FormularioBeneficiario {
  final nombre = TextEditingController();
  final dpi = TextEditingController();
  Parentesco? parentesco;
  DateTime? fechaNacimiento;

  Beneficiario aModelo() => Beneficiario(
        nombre: nombre.text.trim(),
        dpi: Validadores.soloDigitos(dpi.text),
        parentesco: parentesco!,
        fechaNacimiento: fechaNacimiento!,
      );

  void dispose() {
    nombre.dispose();
    dpi.dispose();
  }
}

/// Todo lo que el usuario va llenando en los 4 pasos de la afiliación.
///
/// Los TextEditingController guardan el texto de cada campo. Este objeto vive en la
/// pantalla de afiliación y se comparte con cada paso, así no se pierde nada al ir
/// y venir entre pasos.
class FormularioAfiliacion {
  // Paso 1 · Titular
  final nombre = TextEditingController();
  final dpi = TextEditingController();
  final telefono = TextEditingController();
  final email = TextEditingController();
  final direccion = TextEditingController();
  final nit = TextEditingController();
  final password = TextEditingController();
  final confirmarPassword = TextEditingController();
  ArchivoAdjunto? dpiFrente;
  ArchivoAdjunto? dpiReverso;

  // Paso 2 · Beneficiarios (de 0 a 4)
  final beneficiarios = <FormularioBeneficiario>[];

  // Paso 3 · Mascota (opcional)
  bool tieneMascota = false;
  final mascotaNombre = TextEditingController();
  final mascotaRaza = TextEditingController();
  final mascotaPeso = TextEditingController();
  Especie? mascotaEspecie;
  ArchivoAdjunto? mascotaFoto;

  // Paso 4 · Términos y firma
  bool aceptaTerminos = false;
  final firma = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool get puedeAgregarBeneficiario => beneficiarios.length < maxBeneficiarios;

  bool get mascotaExcedePeso =>
      (Validadores.convertirPeso(mascotaPeso.text) ?? 0) > pesoMaxMascotaKg;

  /// Arma la solicitud final. Se llama solo después de validar todos los pasos.
  Future<SolicitudAfiliacion> aSolicitud() async {
    final firmaPng = await firma.toPngBytes();

    return SolicitudAfiliacion(
      titular: Titular(
        nombre: nombre.text.trim(),
        dpi: Validadores.soloDigitos(dpi.text),
        telefono: Validadores.soloDigitos(telefono.text),
        email: email.text.trim().toLowerCase(),
        direccion: direccion.text.trim(),
        nit: Validadores.normalizarNit(nit.text),
        password: password.text,
      ),
      dpiFrente: dpiFrente!,
      dpiReverso: dpiReverso!,
      beneficiarios: beneficiarios.map((b) => b.aModelo()).toList(),
      mascota: tieneMascota
          ? Mascota(
              nombre: mascotaNombre.text.trim(),
              especie: mascotaEspecie!,
              raza: mascotaRaza.text.trim(),
              pesoKg: Validadores.convertirPeso(mascotaPeso.text)!,
              foto: mascotaFoto!,
            )
          : null,
      firma: ArchivoAdjunto(bytes: firmaPng!, nombre: 'firma.png', mime: 'image/png'),
      aceptaTerminos: aceptaTerminos,
      origen: _origen,
    );
  }

  static String get _origen {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'app_android',
      TargetPlatform.iOS => 'app_ios',
      _ => 'otro',
    };
  }

  void dispose() {
    for (final controlador in [
      nombre, dpi, telefono, email, direccion, nit, password, confirmarPassword, //
      mascotaNombre, mascotaRaza, mascotaPeso,
    ]) {
      controlador.dispose();
    }
    for (final b in beneficiarios) {
      b.dispose();
    }
    firma.dispose();
  }
}
