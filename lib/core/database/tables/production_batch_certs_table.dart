import 'package:drift/drift.dart';

/// Production batch certificates junction table for offline storage
///
/// Stores the many-to-many relationship between batches and certificates.
@DataClassName('ProductionBatchCertLocal')
class ProductionBatchCerts extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // Junction data
  IntColumn get productionBatchLocalId => integer()();
  TextColumn get batchCertId => text()(); // Remote UUID of certificate
  TextColumn get cooperativeId => text()();

  // Synchronization fields (MANDATORY)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
