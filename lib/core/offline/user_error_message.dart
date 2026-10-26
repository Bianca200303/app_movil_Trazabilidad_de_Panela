import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/offline/network_errors.dart';

/// Textos técnicos que delatan un problema de red aunque el error original
/// haya sido envuelto en un `Exception('...: $e')` por algún servicio.
const _networkErrorHints = [
  'SocketException',
  'ClientException',
  'TimeoutException',
  'HandshakeException',
  'Failed host lookup',
  'No route to host',
  'Connection refused',
  'Connection reset',
  'Network is unreachable',
];

/// Indica si [error] se debe a la falta de conexión con el servidor.
///
/// Solo para decidir QUÉ MOSTRAR al usuario. Para decidir si un envío se
/// reintenta usar [isTransientNetworkError], que mira el tipo real del error
/// y no su texto.
bool looksLikeNetworkError(Object error) {
  if (isTransientNetworkError(error)) return true;
  final text = error.toString();
  return _networkErrorHints.any(text.contains);
}

/// Mensaje corto y entendible para mostrar en pantalla, en lugar del error
/// técnico completo. [action] describe lo que falló, p. ej.
/// "No se pudieron cargar los módulos".
String userErrorMessage(Object error, {required String action}) {
  if (looksLikeNetworkError(error)) {
    return '$action: no hay conexión con el servidor. '
        'Inténtelo de nuevo cuando tenga señal.';
  }
  final detail = error is PostgrestException
      ? error.message
      : error.toString().replaceAll('Exception: ', '');
  const maxLength = 160;
  final shortDetail = detail.length > maxLength
      ? '${detail.substring(0, maxLength)}…'
      : detail;
  return '$action: $shortDetail';
}
