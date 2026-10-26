import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Indica si un error de envío es pasajero (falta de señal, tiempo agotado,
/// sesión que no se pudo renovar sin conexión) y por lo tanto conviene
/// reintentar más tarde, en vez de tratar el registro como rechazado.
///
/// Un [PostgrestException] común (RLS, validación de un trigger, dato
/// inválido) NO es pasajero: reintentar daría el mismo resultado.
bool isTransientNetworkError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException ||
      error is ClientException ||
      error is AuthRetryableFetchException) {
    return true;
  }

  // PGRST301 = JWT vencido/inválido: la sesión se renueva al volver la señal.
  if (error is PostgrestException && error.code == 'PGRST301') return true;

  return false;
}
