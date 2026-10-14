import 'package:url_launcher/url_launcher.dart';

/// Abre la página de pago de Odoo en el navegador integrado de la app (Custom Tabs en Android,
/// Safari View Controller en iOS). La tarjeta se escribe ahí, nunca en la app. Al cerrarlo, el
/// usuario vuelve a la app y "Mi membresía" se actualiza sola.
Future<bool> abrirPaginaDePago(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
