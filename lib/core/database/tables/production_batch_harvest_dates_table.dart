import 'package:drift/drift.dart';

/// Additional harvest dates table for offline storage
///
/// Stores extra "fecha de corte" entries for a production batch, beyond the
/// primary harvestDate already on ProductionBatches -- used when cane
/// processed on one processDate comes from several different cut dates.
@DataClassName('ProductionBatchHarvestDateLocal')
class ProductionBatchHarvestDates extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productionBatchLocalId => integer()();
  DateTimeColumn get harvestDate => dateTime()();
  TextColumn get cooperativeId => text()();

  // Synchronization fields (MANDATORY)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
