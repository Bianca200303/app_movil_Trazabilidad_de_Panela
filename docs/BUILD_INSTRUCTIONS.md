# Build Instructions for Different Cooperatives

Este archivo explica cómo construir la aplicación para diferentes cooperativas usando configuración centralizada.

## Configuración Actual

- **Por defecto**: NORANDINO
- **Configuración centralizada**: `lib/core/app_config.dart`
- **IDs de cooperativas**: Sincronizados con Supabase seed data

## Builds por Cooperativa

### Para Norandino (Development - por defecto)
```bash
flutter run
# o
flutter run --dart-define=COOPERATIVE_CODE=NORANDINO
```

### Para CAES
```bash
flutter run --dart-define=COOPERATIVE_CODE=CAES
```

### Para Production Builds

#### Norandino APK
```bash
flutter build apk --dart-define=COOPERATIVE_CODE=NORANDINO --dart-define=SUPABASE_URL=<production_url> --dart-define=SUPABASE_ANON_KEY=<production_key>
```

#### CAES APK
```bash
flutter build apk --dart-define=COOPERATIVE_CODE=CAES --dart-define=SUPABASE_URL=<production_url> --dart-define=SUPABASE_ANON_KEY=<production_key>
```

## Variables de Entorno Disponibles

- `COOPERATIVE_CODE`: Determina qué cooperativa usar (NORANDINO, CAES)
- `SUPABASE_URL`: URL del proyecto Supabase
- `SUPABASE_ANON_KEY`: Clave anónima de Supabase

## Configuraciones de Cooperativas

### NORANDINO
- **ID**: `550e8400-e29b-41d4-a716-446655440001`
- **Code**: `NORANDINO`
- **Name**: `Cooperativa Agraria Norandino`

### CAES
- **ID**: `550e8400-e29b-41d4-a716-446655440002`
- **Code**: `CAES`
- **Name**: `Cooperativa Agraria Ecológica y Solidaria Piura`

## Agregar Nueva Cooperativa

1. Agregar cooperativa en Supabase (migration + seed)
2. Agregar configuración en `CooperativeConfigs` class
3. Agregar case en `AppConfig._getCurrentConfig()`
4. Usar nuevo `COOPERATIVE_CODE` en build

## Notas Importantes

- Los IDs deben coincidir exactamente con los UUIDs en Supabase
- Cada usuario se registra automáticamente con la cooperativa configurada en build time
- RLS garantiza que solo vean datos de su cooperativa
- La configuración es inmutable en runtime - se determina en build time