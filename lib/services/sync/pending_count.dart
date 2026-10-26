import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/offline_config.dart';

/// Total de registros guardados en el celular que todavía no llegaron al
/// servidor (productores, parcelas, lotes y la bandeja de controles).
///
/// Única fuente para el contador del botón de sincronizar, el progreso de
/// SyncService y el bloqueo de cierre de sesión.
Future<int> countPendingSync(AppDatabase db) async {
  var count = 0;

  if (OfflineConfig.instance.features.producers) {
    count += await db.producersDao.countPending();
    count += await db.plotsDao.countPending();
  }

  if (OfflineConfig.instance.features.production) {
    count += await db.productionBatchesDao.countPending(AppConfig.current.id);
  }

  count += await db.pendingSubmissionsDao.countAll();

  return count;
}
