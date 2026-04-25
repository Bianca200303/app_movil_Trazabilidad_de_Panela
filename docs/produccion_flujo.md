# Flujo de registro de producción (móvil)

Documenta paso a paso cómo se construye y persiste un lote de producción desde la app móvil. Incluye widgets involucrados, tablas locales (Drift) y remotas (Supabase), y el comportamiento offline-first.

> Ámbito: app **Flutter móvil**. La web React no usa estas tablas para registrar producción de campo (solo las consume para historial y trazabilidad).

---

## 1. Pantalla y orquestador

`lib/screens/production_registration_screen.dart` (`ProductionRegistrationScreen`)

- Stateful + ConsumerState (Riverpod).
- Mantiene **14 TextEditingController**, listas (`_temperatures`, `_certificates`), selecciones (`_selectedProducer`, `_selectedPlot`), ubicación (`_locationLatitude/Longitude/Text`), densidad (`_density`) y bandera de admin (`_isAdminSistema`).
- Variable `_currentStep` controla qué widget se muestra (8 pasos secuenciales).
- Al inicializar:
  - Inyecta `AppDatabase` desde `appDatabaseProvider`.
  - Lee densidad inicial desde `caneDensityProvider`.
  - Lee `currentUserProvider` para saber si es admin.
  - Suscribe a cambios de densidad con `ref.listenManual`.
  - Llama `_loadCertificates()` para traer el catálogo de certificaciones.
  - Listener sobre `_plotController` que dispara `_loadSelectedProducerAndPlot()`.

---

## 2. Pasos del flujo

| # | Step (clase) | Widget archivo | Datos que captura |
|---|---|---|---|
| 0 | `ProducerSelectionStep` | `widgets/production/producer_selection_step.dart` | Productor, parcela, ubicación, defaults % extracción y % cachaza |
| 1 | `DateSelectionStep` | `widgets/production/date_selection_step.dart` | Fecha cosecha (DD/MM/YYYY), fecha proceso |
| 2 | `SugarCaneTypeStep` | `widgets/production/sugar_cane_type_step.dart` | Selección de certificaciones (con grupos de exclusión) |
| 3 | `ResultsInputStep` | `widgets/production/results_input_step.dart` | Litros de jugo, kg de panela, kg de confitillo, % extracción, % cachaza |
| 4 | `SugarCaneDetailsStep` | `widgets/production/sugar_cane_details_step.dart` | (Solo muestra cálculos derivados) |
| 5 | `PhControlStep` | `widgets/production/ph_control_step.dart` | pH inicial, regulador (cantidad+unidad), pH final |
| 6 | `TemperatureControlStep` | `widgets/production/temperature_control_step.dart` | Lista dinámica de temperaturas en paila |
| 7 | `RegistrationSummaryStep` | `widgets/production/registration_summary_step.dart` | Resumen + botón **GUARDAR LOTE** |

Validaciones por paso:
- Paso 2 → `_validateAndNextStep()` chequea que se haya seleccionado al menos una certificación de cada `exclusion_group` que sea `is_required`.
- Paso 3 → `_validateResultsAndNextStep()` valida que jugo > 0, panela ≥ 0, confitillo ≥ 0, y que panela < jugo.
- Paso 7 → `_validateInputData()` valida pH (0-14), no-vacíos, rangos numéricos.

---

## 3. Generación del código de lote

`core/batch_code_generator.dart` (`BatchCodeGenerator.generate`)

- El paso 7 (`RegistrationSummaryStep`) llama `_generateBatchCode()` en `initState`.
- Combina `cooperativePrefix` (de `AppConfig.current.batchCodePrefix`) con `harvestDate` para producir un código único.
- Si el guardado falla, se regenera para evitar conflictos al reintentar.

---

## 4. Servicio de guardado

`lib/services/production_batch_service.dart` (`ProductionBatchService.createProductionBatch`)

**Flag**: `OfflineConfig.instance.features.production`. Si `false` o `_db == null`, va directo a `createOnline(request)`.

### 4.1 Modo offline-first (default)

1. **Resuelve LOCAL IDs** del productor (`_resolveProducerLocalId`) y parcela (`_resolvePlotLocalId`).
2. **Genera/usa el `batchCode`** (puede venir pre-generado del summary).
3. **Calcula campos derivados** con `ProductionCalculator`:
   - `juiceWeightKg = juiceLiters × density`
   - `caneKg = juiceWeightKg / (extractionPercentage / 100)`
   - `efficiency = (panelaKg / juiceLiters) × 100` (clamp 0-999.99)
4. **Inserta en `production_batches` (Drift)** con `syncStatus = pending`.
5. **Guarda relacionadas en local**:
   - `_saveBatchCerts(batchLocalId, selectedCertificateIds)` → `production_batch_certs`
   - `_saveBatchTemperatures(batchLocalId, temperatures)` → tabla de temperaturas (`batch_temperatures` o equivalente)
   - `_saveBatchPhControl(batchLocalId, request)` → tabla de pH (`batch_ph_control` o equivalente)
6. **Verifica conectividad** con `NetworkDetector().isConnected`.
7. **Si online**: intenta sync inmediato.
   - Verifica que productor y parcela tengan `remoteId` (si no, no se puede subir aún).
   - Llama `createOnline(remoteRequest)` con UUIDs.
   - Si éxito → `markAsSynced(localId, remoteId)` + `_markRelatedAsSynced(db, batchLocalId)`.
   - Si falla → log de warning, queda `pending`.
8. **Si offline**: queda `pending`. Se sincronizará luego por `ProductionSyncService`.
9. **Devuelve** `ProductionBatch` (remoto si sincronizó, local si no).

### 4.2 Modo online directo (`createOnline`)

- Inserta directo en Supabase usando `supabase.from('production_batches').insert(...).select().single()`.
- Después inserta filas en `production_batch_certs` con el `production_batch_id` retornado.

---

## 5. Tablas involucradas

### 5.1 Locales (Drift)

`lib/core/database/tables/`

| Tabla | Rol |
|---|---|
| `production_batches_table.dart` (`ProductionBatches`) | Lote en sí. Incluye `syncStatus`, `remoteId`, `syncedAt`, `latitude`, `longitude`, `locationText`, `caneDensity`. FKs locales (no UUIDs). |
| `production_batch_certs_table.dart` (`ProductionBatchCerts`) | Junction lote-certificación. Guarda `productionBatchLocalId` (FK local) + `batchCertId` (UUID remoto). |
| (relacionadas adicionales: temperaturas, pH control — verificar nombre exacto en `core/database/tables/`) | |

DAOs en `lib/core/database/daos/`: `production_batches_dao.dart`, `production_batch_certs_dao.dart`.

### 5.2 Remotas (Supabase)

`supabase/mi-proyecto/supabase/seed.sql`

| Tabla | Rol | Columnas clave |
|---|---|---|
| `production_batches` | Lote producido | `batch_code`, `harvest_date`, `process_date`, `cane_kg`, `juice_liters`, `panela_kg`, `confitillo_kg`, `porcentaje_extraccion`, `cachaza_percentage`, `efficiency_percentage`, `cane_density`, `producer_id`, `plot_id`, `cooperative_id` |
| `production_batch_certs` | Junction M:N | `production_batch_id`, `batch_cert_id`, `cooperative_id` |
| `batch_certs` | Catálogo (NO transaccional) | `id`, `name`, `cooperative_id`, `is_default`, `exclusion_group_id` |
| `certificate_exclusion_groups` | Grupos de selección excluyente | Define grupos donde solo una cert puede estar activa (ej. "Tipo de mercado") |
| `producers`, `plots` | FKs lookup | — |

> Las certificaciones del registro se persisten en `production_batch_certs`, **una fila por cert seleccionada**. El catálogo `batch_certs` solo se lee.

---

## 6. Sincronización en background

`lib/services/sync/production_sync_service.dart`

- Recorre lotes con `syncStatus = pending` o `modified`.
- Sube primero los lotes que tienen FKs (productor/parcela) ya sincronizados; los demás esperan.
- Al éxito, marca `syncStatus = synced` y graba `remoteId` + `syncedAt`.

---

## 7. Pantalla de éxito

`lib/screens/success_registration_screen.dart` (`SuccessRegistrationScreen`)

- Se navega con `MaterialPageRoute` desde `RegistrationSummaryStep._saveProductionBatch`.
- Mensaje genérico: "Lote de producción registrado exitosamente".
- **No distingue** hoy si el guardado fue solo local (offline) o ya sincronizado.

---

## 8. Resumen del recorrido de un dato

Ejemplo: el operario captura **65 °C** en el paso 6.

1. Se almacena en `_temperatures` de `_ProductionRegistrationScreenState` (`production_registration_screen.dart`).
2. Llega al paso 7 vía prop `temperatures: _temperatures`.
3. Al pulsar GUARDAR LOTE → `RegistrationSummaryStep._saveProductionBatch()` arma `CreateProductionBatchRequest(temperatures: widget.temperatures, ...)`.
4. `ProductionBatchService.createProductionBatch()` llama `_saveBatchTemperatures(batchLocalId, request.temperatures)`.
5. Si online y FKs sincronizadas, también se sube a Supabase en la tabla correspondiente con el `production_batch_id` remoto.
6. Si offline, queda en local con `syncStatus = pending` y se subirá después.
