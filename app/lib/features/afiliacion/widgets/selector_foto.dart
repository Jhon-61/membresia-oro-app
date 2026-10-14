import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/afiliacion.dart';

/// Campo de formulario para tomar o elegir una foto.
///
/// Es un FormField, así que el Form lo valida igual que a un TextFormField
/// (muestra el error en rojo si la foto es obligatoria y falta).
class SelectorFoto extends StatelessWidget {
  const SelectorFoto({
    super.key,
    required this.etiqueta,
    required this.valorInicial,
    required this.alCambiar,
    this.mensajeObligatorio = 'Agrega la foto',
    this.ayuda,
  });

  final String etiqueta;
  final ArchivoAdjunto? valorInicial;
  final ValueChanged<ArchivoAdjunto> alCambiar;
  final String mensajeObligatorio;
  final String? ayuda;

  // Comprimir ANTES de enviar: una foto del celular pesa 3–5 MB; así queda en ~200 KB.
  static const _anchoMaximo = 1600.0;
  static const _calidadJpeg = 75;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return FormField<ArchivoAdjunto>(
      initialValue: valorInicial,
      validator: (archivo) => archivo == null ? mensajeObligatorio : null,
      builder: (campo) {
        final archivo = campo.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: textos.titleSmall),
            if (ayuda != null) Text(ayuda!, style: textos.bodySmall),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _elegirFoto(context, campo),
              child: Container(
                height: 170,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colores.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: campo.hasError ? colores.error : colores.outline),
                ),
                child: archivo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: colores.primary),
                          const SizedBox(height: 8),
                          const Text('Tomar o elegir foto'),
                        ],
                      )
                    : Image.memory(archivo.bytes, fit: BoxFit.cover),
              ),
            ),
            if (archivo != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${archivo.tamanoKb} KB · toca la foto para cambiarla',
                    style: textos.bodySmall),
              ),
            if (campo.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(campo.errorText!,
                    style: textos.bodySmall?.copyWith(color: colores.error)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _elegirFoto(BuildContext context, FormFieldState<ArchivoAdjunto> campo) async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (contextoHoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(contextoHoja, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(contextoHoja, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final foto = await ImagePicker().pickImage(
      source: origen,
      maxWidth: _anchoMaximo,
      maxHeight: _anchoMaximo,
      imageQuality: _calidadJpeg,
    );
    if (foto == null || !campo.mounted) return;

    final archivo = ArchivoAdjunto(
      bytes: await foto.readAsBytes(),
      nombre: foto.name,
      mime: foto.mimeType ?? 'image/jpeg',
    );
    if (!campo.mounted) return;
    campo.didChange(archivo);
    alCambiar(archivo);
  }
}
