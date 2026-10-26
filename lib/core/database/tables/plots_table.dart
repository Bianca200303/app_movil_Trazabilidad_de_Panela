import 'package:drift/drift.dart';

/// Plots table for offline storage
///
/// Stores plot data locally with synchronization tracking fields.
/// Each plot belongs to a producer and has auto-generated codes.
class Plots extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // Plot data fields
  TextColumn get name => text()();
  TextColumn get code => text()();

  /// % por defecto de la parcela (los del último lote, o los que fijó un
  /// administrador). Se guardan para que el registro de producción los use
  /// también sin conexión; null = se usa el del productor o el del sistema.
  RealColumn get defaultExtractionPercentage => real().nullable()();
  RealColumn get defaultCachazaPercentage => real().nullable()();

  /// Foreign key to local producers table
  IntColumn get producerLocalId => integer()();

  // Synchronization fields (MANDATORY for offline tables)
  /// Sync status: 0=pending, 1=synced, 2=modified
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// Remote UUID from Supabase (null if not synced yet)
  TextColumn get remoteId => text().nullable()();

  /// Remote producer UUID from Supabase
  TextColumn get remoteProducerId => text().nullable()();

  /// Created at timestamp (local)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last synced at timestamp (null if never synced)
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Index> get indexes => {
        // Unique index on remoteId to prevent duplicates when caching from remote
        // Only applies when remoteId is not null (doesn't affect local pending plots)
        Index('plots_remote_id_idx', 'UNIQUE INDEX plots_remote_id_idx ON plots(remote_id) WHERE remote_id IS NOT NULL'),
      };
}
