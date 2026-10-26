import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:panela_sys/core/database/tables/producers_table.dart';
import 'package:panela_sys/core/database/tables/plots_table.dart';
import 'package:panela_sys/core/database/tables/coop_modules_table.dart';
import 'package:panela_sys/core/database/tables/production_batches_table.dart';
import 'package:panela_sys/core/database/tables/batch_temperatures_table.dart';
import 'package:panela_sys/core/database/tables/batch_ph_controls_table.dart';
import 'package:panela_sys/core/database/tables/production_batch_certs_table.dart';
import 'package:panela_sys/core/database/tables/batch_certs_table.dart';
import 'package:panela_sys/core/database/tables/production_batch_harvest_dates_table.dart';
import 'package:panela_sys/core/database/tables/certified_workers_table.dart';
import 'package:panela_sys/core/database/tables/pending_submissions_table.dart';
import 'package:panela_sys/core/database/tables/cached_production_batches_table.dart';
import 'package:panela_sys/core/database/daos/producers_dao.dart';
import 'package:panela_sys/core/database/daos/plots_dao.dart';
import 'package:panela_sys/core/database/daos/coop_modules_dao.dart';
import 'package:panela_sys/core/database/daos/production_batches_dao.dart';
import 'package:panela_sys/core/database/daos/batch_temperatures_dao.dart';
import 'package:panela_sys/core/database/daos/batch_ph_controls_dao.dart';
import 'package:panela_sys/core/database/daos/production_batch_certs_dao.dart';
import 'package:panela_sys/core/database/daos/batch_certs_dao.dart';
import 'package:panela_sys/core/database/daos/production_batch_harvest_dates_dao.dart';
import 'package:panela_sys/core/database/daos/certified_workers_dao.dart';
import 'package:panela_sys/core/database/daos/pending_submissions_dao.dart';
import 'package:panela_sys/core/database/daos/cached_production_batches_dao.dart';
import 'package:panela_sys/core/utils/uuid_v4.dart';

part 'app_database.g.dart';

/// Main Drift database configuration for offline-first functionality
///
/// This database stores local copies of producers, plots, production batches,
/// and reference data (like cooperative modules and batch certificates) with
/// sync status tracking for offline-first operations.
@DriftDatabase(
  tables: [
    Producers,
    Plots,
    CoopModules,
    ProductionBatches,
    BatchTemperatures,
    BatchPhControls,
    ProductionBatchCerts,
    BatchCerts,
    ProductionBatchHarvestDates,
    CertifiedWorkers,
    PendingSubmissions,
    CachedProductionBatches,
  ],
  daos: [
    ProducersDao,
    PlotsDao,
    CoopModulesDao,
    ProductionBatchesDao,
    BatchTemperaturesDao,
    BatchPhControlsDao,
    ProductionBatchCertsDao,
    BatchCertsDao,
    ProductionBatchHarvestDatesDao,
    CertifiedWorkersDao,
    PendingSubmissionsDao,
    CachedProductionBatchesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  // Private constructor
  AppDatabase._internal() : super(_openConnection());

  // Factory constructor for singleton pattern
  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 14;

  /// Migration strategy for handling schema version changes
  ///
  /// Implements step-by-step incremental migrations to preserve user data
  /// when schema changes occur.
  ///
  /// Version history:
  /// - v1-v4: Initial development versions
  /// - v5: Add regulator unit tracking (regulator_quantity_value, regulator_quantity_unit)
  /// - v6: Add cane_density to production_batches for per-batch density tracking
  /// - v7: Add location fields (latitude, longitude, locationText) to production_batches
  /// - v8: Add observations to production_batches
  /// - v9: Add production_batch_harvest_dates (fechas de corte adicionales)
  /// - v10: Add timeBetweenMielesMinutes to batchTemperatures
  /// - v11: Add certified_workers cache (desplegable offline del Control de personal operario)
  /// - v12: Add pending_submissions (bandeja de controles sin enviar) y
  ///        cached_production_batches (lotes recientes del servidor)
  /// - v13: production_batches.clientId (id fijo del celular, envío idempotente)
  ///        y syncError (motivo de rechazo del servidor)
  /// - v14: plots.defaultExtractionPercentage / defaultCachazaPercentage
  ///        (% por defecto de la parcela, para usarlos sin conexión)
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // Create all tables on fresh install
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Incremental migrations - preserves existing data

          // Migration from v4 to v5: Add regulator unit columns
          if (from == 4) {
            await m.addColumn(batchPhControls, batchPhControls.regulatorQuantityValue);
            await m.addColumn(batchPhControls, batchPhControls.regulatorQuantityUnit);
          }
          if (from <= 5) {
            await m.addColumn(productionBatches, productionBatches.caneDensity);
          }
          if (from <= 6) {
            await m.addColumn(productionBatches, productionBatches.latitude);
            await m.addColumn(productionBatches, productionBatches.longitude);
            await m.addColumn(productionBatches, productionBatches.locationText);
          }
          if (from <= 7) {
            await m.addColumn(productionBatches, productionBatches.observations);
          }
          if (from <= 8) {
            await m.createTable(productionBatchHarvestDates);
          }
          if (from <= 9) {
            await m.addColumn(batchTemperatures, batchTemperatures.timeBetweenMielesMinutes);
          }
          if (from <= 10) {
            await m.createTable(certifiedWorkers);
          }
          if (from <= 11) {
            await m.createTable(pendingSubmissions);
            await m.createTable(cachedProductionBatches);
          }
          if (from <= 12) {
            await m.addColumn(productionBatches, productionBatches.clientId);
            await m.addColumn(productionBatches, productionBatches.syncError);
            // Los lotes que estaban sin subir reciben su id fijo ahora.
            final unsent = await (select(productionBatches)
                  ..where((b) => b.remoteId.isNull()))
                .get();
            for (final batch in unsent) {
              await (update(productionBatches)..where((b) => b.id.equals(batch.id)))
                  .write(ProductionBatchesCompanion(clientId: Value(generateUuidV4())));
            }
          }
          if (from <= 13) {
            await m.addColumn(plots, plots.defaultExtractionPercentage);
            await m.addColumn(plots, plots.defaultCachazaPercentage);
          }
        },
      );

  /// Opens SQLite database connection with lazy initialization
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'panela_sys_db.sqlite'));
      return NativeDatabase(file);
    });
  }
}
