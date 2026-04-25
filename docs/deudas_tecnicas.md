# Deudas Técnicas y Mejoras Pendientes

## Seguridad

### [MEDIA] RLS no restringe `registered_by_user_id` por módulo en `production_batches`
Un técnico de campo con JWT válido puede llamar la API de Supabase directamente e insertar un lote con el `producer_id` de cualquier productor de la cooperativa, saltándose el filtro de módulo que existe en Flutter.

**Por qué no se implementó ahora:** Requiere una policy RLS compleja que verifique `user_module_assignments`. El flujo normal ya está protegido en Flutter (`producer_selection_step.dart:135`). El perfil de usuario (técnico de campo en una cooperativa de panela) hace que este vector sea de bajo riesgo práctico.

**Para implementar:** Agregar policy INSERT en `production_batches` que valide que `producer_id` pertenece a un módulo asignado al usuario autenticado, usando un JOIN a `user_module_assignments` y `producers`.

---

### [BAJA] Router de Flutter no verifica roles — solo autenticación
`router.dart` solo chequea si el usuario está autenticado y si la cooperativa está configurada. No hay verificación de rol por ruta. Cada pantalla sensible tiene su propio guard interno (`initState`), pero si se agrega una ruta nueva y se olvida el guard, queda desprotegida.

**Para implementar:** Agregar lógica de role-based redirect en el `redirect` callback de `GoRouter`, mapeando rutas a roles permitidos.
