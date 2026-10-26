import 'package:drift/drift.dart';

/// Bandeja de registros pendientes de envío (controles guardados sin señal).
///
/// Es genérica: cada fila guarda el tipo de registro ([kind]) y sus datos en
/// JSON ([payload]); el envío lo resuelve el manejador registrado para ese
/// tipo (ver services/sync/submissions/). La fila se borra al confirmarse el
/// envío -- no es una copia local del historial.
@DataClassName('PendingSubmissionLocal')
class PendingSubmissions extends Table {
  /// UUID generado en el celular. Es también el id del registro en el
  /// servidor, lo que hace idempotente el reenvío.
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};

  /// Tipo de registro (ej. 'worker_control'); elige el manejador de envío.
  TextColumn get kind => text()();

  /// Datos del registro en JSON.
  TextColumn get payload => text()();

  TextColumn get cooperativeId => text()();

  /// Usuario (auth) que lo creó: solo se envía con la sesión de ese mismo
  /// usuario, para que no quede registrado a nombre de otro.
  TextColumn get createdByAuthUserId => text()();

  /// Lote creado en este celular y aún no enviado del que depende el
  /// registro. Se resuelve a su id del servidor al momento del envío.
  IntColumn get productionBatchLocalId => integer().nullable()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Último error al enviar (null = nunca falló). Se reintenta igual en la
  /// siguiente sincronización.
  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
