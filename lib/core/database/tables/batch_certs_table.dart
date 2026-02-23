import 'package:drift/drift.dart';

/// Batch certificates cache table
///
/// Stores certificate reference data for offline dropdown usage.
/// This is a CACHE table, not a sync table.
@DataClassName('BatchCertLocal')
class BatchCerts extends Table {
  // Use remote UUID as primary key (not autoIncrement)
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};

  // Certificate data
  TextColumn get name => text()();
  TextColumn get exclusionGroupId => text().nullable()();
  BoolColumn get isDefault => boolean()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // Cache metadata (NOT sync fields - this is pure cache)
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}
