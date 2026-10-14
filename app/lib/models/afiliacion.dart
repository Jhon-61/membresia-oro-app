import 'dart:convert';
import 'dart:typed_data';

import '../core/constantes.dart';
import '../core/formato.dart';

// Datos de una solicitud de afiliación, listos para enviarse a Odoo.
// El formato JSON está documentado en docs/API_ODOO.md: si cambias un campo aquí,
// actualiza también ese documento y el módulo de Odoo.

/// Imagen o archivo ya comprimido, listo para enviar.
class ArchivoAdjunto {
  const ArchivoAdjunto({required this.bytes, required this.nombre, required this.mime});

  final Uint8List bytes;
  final String nombre;
  final String mime;

  int get tamanoKb => (bytes.lengthInBytes / 1024).ceil();

  // Odoo guarda las imágenes (fields.Image / fields.Binary) en base64,
  // así que se envían ya convertidas.
  Map<String, dynamic> toJson() => {
        'nombre_archivo': nombre,
        'mime': mime,
        'base64': base64Encode(bytes),
      };
}

enum Parentesco {
  conyuge('conyuge', 'Cónyuge'),
  hijo('hijo', 'Hijo(a)'),
  padre('padre', 'Padre'),
  madre('madre', 'Madre'),
  hermano('hermano', 'Hermano(a)'),
  abuelo('abuelo', 'Abuelo(a)'),
  nieto('nieto', 'Nieto(a)'),
  otro('otro', 'Otro');

  const Parentesco(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;
}

enum Especie {
  perro('perro', 'Perro'),
  gato('gato', 'Gato'),
  otra('otra', 'Otra');

  const Especie(this.valor, this.etiqueta);
  final String valor;
  final String etiqueta;
}

class Titular {
  const Titular({
    required this.nombre,
    required this.dpi,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.nit,
    required this.password,
  });

  final String nombre;
  final String dpi;
  final String telefono;
  final String email;
  final String direccion;

  /// "CF" si es consumidor final.
  final String nit;

  /// Contraseña de la cuenta de la app. Solo viaja a Odoo (por HTTPS) al afiliarse.
  final String password;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'dpi': dpi,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
        'nit': nit,
        'password': password,
      };
}

class Beneficiario {
  const Beneficiario({
    required this.nombre,
    required this.dpi,
    required this.parentesco,
    required this.fechaNacimiento,
  });

  final String nombre;
  final String dpi;
  final Parentesco parentesco;
  final DateTime fechaNacimiento;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'dpi': dpi,
        'parentesco': parentesco.valor,
        'fecha_nacimiento': fechaIso(fechaNacimiento),
      };
}

class Mascota {
  const Mascota({
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.pesoKg,
    required this.foto,
  });

  final String nombre;
  final Especie especie;
  final String raza;
  final double pesoKg;
  final ArchivoAdjunto foto;

  /// Solo informativo: Odoo decide si aplica el cargo extra.
  bool get excedePeso => pesoKg > pesoMaxMascotaKg;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'especie': especie.valor,
        'raza': raza,
        'peso_kg': pesoKg,
        'foto': foto.toJson(),
      };
}

class SolicitudAfiliacion {
  const SolicitudAfiliacion({
    required this.titular,
    required this.dpiFrente,
    required this.dpiReverso,
    required this.beneficiarios,
    required this.mascota,
    required this.firma,
    required this.aceptaTerminos,
    required this.origen,
  });

  final Titular titular;
  final ArchivoAdjunto dpiFrente;
  final ArchivoAdjunto dpiReverso;
  final List<Beneficiario> beneficiarios;
  final Mascota? mascota;
  final ArchivoAdjunto firma;
  final bool aceptaTerminos;

  /// Desde dónde se afilió: app_android, app_ios o web.
  final String origen;

  Map<String, dynamic> toJson() => {
        'titular': titular.toJson(),
        'dpi_frente': dpiFrente.toJson(),
        'dpi_reverso': dpiReverso.toJson(),
        'beneficiarios': beneficiarios.map((b) => b.toJson()).toList(),
        'mascota': mascota?.toJson(),
        'firma': firma.toJson(),
        'acepta_terminos': aceptaTerminos,
        'version_terminos': versionTerminos,
        'origen': origen,
      };
}
