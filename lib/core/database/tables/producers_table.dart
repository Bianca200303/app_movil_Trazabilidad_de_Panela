import 'package:drift/drift.dart';

/// Producers table for offline storage
///
/// Stores producer data locally with synchronization tracking fields.
/// Each producer has sync status to manage offline-first operations.
class Producers extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // Producer data fields
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get dni => text()();
  TextColumn get coopModuleId => text()();
  TextColumn get cooperativeId => text()();
  BoolColumn get isMember => boolean()();
  TextColumn get appagropCode => text().nullable()();

  // Synchronization fields (MANDATORY for offline tables)
  /// Sync status: 0=pending, 1=synced, 2=modified
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// Remote UUID from Supabase (null if not synced yet)
  TextColumn get remoteId => text().nullable()();

  /// Created at timestamp (local)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last synced at timestamp (null if never synced)
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Index> get indexes => {
        // Unique index on remoteId to prevent duplicates when caching from remote
        // Only applies when remoteId is not null (doesn't affect local pending producers)
        Index('producers_remote_id_idx', 'UNIQUE INDEX producers_remote_id_idx ON producers(remote_id) WHERE remote_id IS NOT NULL'),
      };
}
