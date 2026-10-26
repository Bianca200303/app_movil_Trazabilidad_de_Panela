import 'package:drift/drift.dart';

/// Copia local de los lotes de producción recientes del servidor (últimos
/// [kRecentBatchesDays] días), para poder elegir el lote de un control sin
/// señal. Es CACHÉ: se reemplaza al iniciar sesión y al consultar con señal.
///
/// Los lotes creados en este celular y aún no enviados viven en
/// production_batches (tabla de sincronización), no aquí.
@DataClassName('CachedProductionBatchLocal')
class CachedProductionBatches extends Table {
  /// UUID del lote en el servidor.
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get coopModuleId => text()();

  /// Fecha de proceso 'YYYY-MM-DD' (mismo formato que Supabase `date`).
  TextColumn get processDate => text()();

  /// Fila tal como la devuelve el servidor (lote + productor), en JSON.
  TextColumn get payload => text()();

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Días hacia atrás de lotes que se guardan en el celular.
const kRecentBatchesDays = 30;
