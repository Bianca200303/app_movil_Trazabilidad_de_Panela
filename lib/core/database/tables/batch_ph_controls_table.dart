import 'package:drift/drift.dart';

/// Batch pH controls table for offline storage
///
/// Stores pH control measurements for each production batch.
@DataClassName('BatchPhControlLocal')
class BatchPhControls extends Table {
  /// Local auto-increment ID
  IntColumn get id => integer().autoIncrement()();

  // pH control data
  IntColumn get productionBatchLocalId => integer()();
  DateTimeColumn get recordDate => dateTime()();
  TextColumn get regulatorType => text()();
  RealColumn get phInitial => real()();
  RealColumn get phFinal => real()();
  RealColumn get regulatorQuantityValue => real().nullable()();
  TextColumn get regulatorQuantityUnit => text().nullable()();
  RealColumn get brix => real().nullable()();
  TextColumn get correctiveAction => text().nullable()();
  TextColumn get cooperativeId => text()();

  // Synchronization fields (MANDATORY)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  TextColumn get remoteId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
