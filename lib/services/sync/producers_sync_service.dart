import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

/// Sync service for Producers
///
/// Handles uploading pending producers to Supabase and marking them as synced.
/// Provides detailed logging for debugging synchronization operations.
class ProducersSyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  ProducersSyncService(this._db);

  /// Synchronize all pending producers
  ///
  /// Yields after each producer is successfully synced.
  /// Logs all data sent to and received from Supabase.
  Stream<void> sync() async* {
    DebugLogger.info(
        'ProducersSyncService', 'sync', 'Iniciando sincronización de productores');

    final pending = await _db.producersDao.getPending();

    DebugLogger.info(
        'ProducersSyncService', 'sync', 'Productores pendientes: ${pending.length}');

    if (pending.isEmpty) {
      DebugLogger.info(
          'ProducersSyncService', 'sync', 'No hay productores pendientes de sync');
      return;
    }

    for (final producer in pending) {
      bool synced = false;

      try {
        DebugLogger.info(
            'ProducersSyncService',
            'sync',
            'Syncing producer: localId=${producer.id}, '
            'dni=${producer.dni}, '
            'name=${producer.firstName} ${producer.lastName}');

        // Prepare insert data
        final insertData = {
          'first_name': producer.firstName,
          'last_name': producer.lastName,
          'dni': producer.dni,
          'cooperative_id': producer.cooperativeId,
          'coop_module_id': producer.coopModuleId,
          'is_member': producer.isMember,
        };

        if (producer.appagropCode != null && producer.appagropCode!.isNotEmpty) {
          insertData['appagrop_code'] = producer.appagropCode!;
        }

        DebugLogger.debug('ProducersSyncService', 'sync',
            'Sending to Supabase: $insertData');

        // Insert to Supabase
        final response = await _supabase
            .from('producers')
            .insert(insertData)
            .select()
            .single();

        DebugLogger.debug('ProducersSyncService', 'sync',
            'Received from Supabase: $response');

        final remoteId = response['id'] as String;

        DebugLogger.info(
            'ProducersSyncService', 'sync', 'Remote ID received: $remoteId');

        // Mark as synced
        await _db.producersDao.markAsSynced(
          localId: producer.id,
          remoteId: remoteId,
        );

        DebugLogger.info(
            'ProducersSyncService',
            'sync',
            'Producer synced successfully: localId=${producer.id}, remoteId=$remoteId');

        synced = true;
      } catch (e, st) {
        if (e is PostgrestException) {
          // Handle duplicate DNI
          if (e.code == '23505' &&
              e.message.contains('unique_dni_per_cooperative')) {
            DebugLogger.warning(
                'ProducersSyncService',
                'sync',
                'Producer ${producer.id} already exists in Supabase (DNI: ${producer.dni}). '
                'Skipping sync.');
            // Skip this producer and continue with next one
            synced = false;
          } else {
            DebugLogger.error('ProducersSyncService', 'sync',
                'Error syncing producer ${producer.id}: $e',
                stackTrace: st);
            rethrow;
          }
        } else {
          DebugLogger.error('ProducersSyncService', 'sync',
              'Error syncing producer ${producer.id}: $e',
              stackTrace: st);
          rethrow;
        }
      }

      if (synced) {
        yield null;
      }
    }

    DebugLogger.info('ProducersSyncService', 'sync',
        'Sincronización de productores completada');
  }
}
