import 'package:drift/drift.dart';

/// Batch temperatures table for offline storage
///
/// Stores temperature measurements for each production batch.
@DataClassName('BatchTemperatureLocal')
class BatchTemperatures extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // Temperature data
  IntColumn get productionBatchLocalId => integer()();
  RealColumn get temperature => real()();
  IntColumn get sequenceNumber => integer()();
  TextColumn get cooperativeId => text()();

  /// Minutos transcurridos desde la miel anterior (opcional, pareado con
  /// esta temperatura puntual).
  RealColumn get timeBetweenMielesMinutes => real().nullable()();

  // Synchronization fields (MANDATORY)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
