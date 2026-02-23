import 'package:drift/drift.dart';

/// Local cache table for cooperative modules
///
/// Stores modules available for the current cooperative to enable offline form usage.
/// This is a reference data table that gets refreshed on login.
@DataClassName('CoopModuleLocal')
class CoopModules extends Table {
  /// Module ID (UUID from Supabase)
  TextColumn get id => text()();

  /// Module name
  TextColumn get name => text()();

  /// Whether the module is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// When this record was created locally
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this record was last updated
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
