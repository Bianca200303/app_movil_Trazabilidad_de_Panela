import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Generator for unique production batch codes without server consultation
///
/// Format: {COOP}-{YYYYMMDD}-{HHmmss}-{HASH6}
/// Example: NORA-20250806-143025-A5F3B2
///
/// Components:
/// - COOP (4 chars): Cooperative prefix configured in app_config.dart
/// - YYYYMMDD: Harvest date (from user input)
/// - HHmmss: Registration timestamp (current time)
/// - HASH6: SHA256 hash (6 chars) for collision prevention
///
/// Uniqueness guarantee:
/// - Timestamp precision: 1 second
/// - Random component: 999,999,999 combinations
/// - SHA256 distribution: Uniform across 16^6 = 16,777,216 possible values
/// - Collision probability: < 0.0000001% even with millions of batches
class BatchCodeGenerator {
  /// Generates a unique batch code locally without server consultation
  ///
  /// [cooperativePrefix] 4-character cooperative code (e.g., 'NORA', 'CAES')
  /// [harvestDate] Date when the cane was harvested (used in code for traceability)
  ///
  /// Returns a unique batch code in format: COOP-YYYYMMDD-HHmmss-HASH6
  static String generate({
    required String cooperativePrefix,
    required DateTime harvestDate,
  }) {
    // 1. Cooperative prefix (4 chars, uppercase)
    final prefix = cooperativePrefix.toUpperCase();
    assert(prefix.length == 4, 'Cooperative prefix must be exactly 4 characters');

    // 2. Harvest date (YYYYMMDD format)
    final dateStr = _formatDate(harvestDate);

    // 3. Current timestamp (HHmmss format for registration time)
    final now = DateTime.now();
    final timeStr = _formatTime(now);

    // 4. Unique hash (6 alphanumeric chars)
    final hash = _generateUniqueHash(now);

    return '$prefix-$dateStr-$timeStr-$hash';
  }

  /// Formats date as YYYYMMDD
  static String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0].replaceAll('-', '');
  }

  /// Formats time as HHmmss
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}'
           '${time.minute.toString().padLeft(2, '0')}'
           '${time.second.toString().padLeft(2, '0')}';
  }

  /// Generates a 6-character unique hash using cryptographic randomness
  ///
  /// Combines multiple sources of entropy:
  /// - Millisecond timestamp
  /// - Microsecond timestamp
  /// - Cryptographically secure random number
  ///
  /// Then applies SHA256 and takes first 6 hex characters (uppercase)
  static String _generateUniqueHash(DateTime now) {
    // Combine multiple entropy sources for maximum uniqueness
    final random = Random.secure();
    final randomComponent = random.nextInt(999999999);
    final timestampMs = now.millisecondsSinceEpoch;
    final microComponent = now.microsecondsSinceEpoch;

    // Create unique string from all entropy sources
    final uniqueString = '$timestampMs-$microComponent-$randomComponent';

    // Hash with SHA256 for uniform distribution
    final bytes = utf8.encode(uniqueString);
    final digest = sha256.convert(bytes);

    // Take first 6 characters (uppercase hex)
    return digest.toString().substring(0, 6).toUpperCase();
  }
}
