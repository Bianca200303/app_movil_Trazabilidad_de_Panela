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

  // Location fields (nullable - location is optional)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationText => text().nullable()();

  // Observaciones opcionales (capturadas en campo, editables en planta)
  TextColumn get observations => text().nullable()();

  // Synchronization fields (MANDATORY for offline tables)
  /// Sync status: 0=pending, 1=synced, 2=modified
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  /// Remote UUID from Supabase (null if not synced yet)
  TextColumn get remoteId => text().nullable()();

  /// UUID generado en el celular al registrar el lote; es el id con el que
  /// se crea en el servidor (submit_production_batch), así un reenvío tras
  /// un corte de señal no lo duplica. Nullable solo por los lotes ya
  /// sincronizados antes de la v13; los pendientes lo reciben al migrar.
  TextColumn get clientId => text().nullable()();

  /// Motivo por el que el servidor rechazó el lote (dato inválido, parcela
  /// que no corresponde, etc.); null si nunca fue rechazado. Un lote
  /// rechazado no frena el envío de los demás.
  TextColumn get syncError => text().nullable()();

  /// Created at timestamp (local)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last synced at timestamp (null if never synced)
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
