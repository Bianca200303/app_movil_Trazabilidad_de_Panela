import 'dart:math';

/// Genera un UUID v4 (RFC 4122) con un generador criptográficamente seguro.
///
/// Se usa como id de los registros que se guardan sin conexión: el celular
/// fija el id al guardar, y el servidor lo usa como clave para que un
/// reenvío del mismo registro no lo duplique.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
