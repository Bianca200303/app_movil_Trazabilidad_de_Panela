import 'package:drift/drift.dart';

/// Certified workers cache table
///
/// Stores the cooperative's active certified workers (all modules) so the
/// "Nombre y Apellidos" dropdown of the Control de personal operario works
/// without signal. This is a CACHE table, not a sync table: it is replaced
/// on login and the list is maintained from the web (Catálogos).
@DataClassName('CertifiedWorkerLocal')
class CertifiedWorkers extends Table {
  // Use remote UUID as primary key (not autoIncrement)
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get coopModuleId => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get position => text().nullable()();

  /// Certification end date as 'YYYY-MM-DD' (same as Supabase `date`).
  /// Null = no expiry. Only used to warn, never to hide the worker.
  TextColumn get certifiedUntil => text().nullable()();

  // Cache metadata (NOT sync fields - this is pure cache)
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}
