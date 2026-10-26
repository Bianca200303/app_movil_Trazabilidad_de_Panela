import 'package:supabase_flutter/supabase_flutter.dart';

/// Trae todas las filas de una consulta, de a [pageSize] por vez.
///
/// Supabase (PostgREST) devuelve como máximo 1000 filas por consulta y corta
/// el resto sin error: con muchos usuarios o productores las listas quedarían
/// incompletas. [query] arma la consulta desde cero en cada página (un
/// builder de Supabase no se puede reusar) y debe tener un orden estable
/// (p. ej. terminar en `.order('id')`) para no repetir ni saltar filas.
Future<List<Map<String, dynamic>>> fetchAllRows(
  PostgrestTransformBuilder<PostgrestList> Function() query, {
  int pageSize = 1000,
}) async {
  final rows = <Map<String, dynamic>>[];
  for (var from = 0;; from += pageSize) {
    final page = await query().range(from, from + pageSize - 1);
    rows.addAll(page);
    if (page.length < pageSize) return rows;
  }
}
