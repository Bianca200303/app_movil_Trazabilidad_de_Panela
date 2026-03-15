import 'package:drift/drift.dart';

/// Production batches table for offline storage
///
/// Stores production batch data locally with synchronization tracking fields.
@DataClassName('ProductionBatchLocal')
class ProductionBatches extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // Batch data fields (match Supabase schema)
  TextColumn get batchCode => text()();
  DateTimeColumn get harvestDate => dateTime()();
  DateTimeColumn get processDate => dateTime()();
  RealColumn get caneKg => real()();
  RealColumn get juiceLiters => real()();
  RealColumn get panelaKg => real()();
  RealColumn get confitilloKg => real()();
  RealColumn get porcentajeExtraccion => real().nullable()();
  RealColumn get cachazaPercentage => real().nullable()();
  RealColumn get efficiencyPercentage => real()();
  RealColumn get caneDensity => real().withDefault(const Constant(1.05))();

  // Foreign keys (LOCAL IDs - not UUIDs)
  IntColumn get producerLocalId => integer()();
  IntColumn get plotLocalId => integer().nullable()();
  TextColumn get cooperativeId => text()();

  // Synchronization fields (MANDATORY for offline tables)
  /// Sync status: 0=pending, 1=synced, 2=modified
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// Remote UUID from Supabase (null if not synced yet)
  TextColumn get remoteId => text().nullable()();

  /// Created at timestamp (local)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last synced at timestamp (null if never synced)
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
