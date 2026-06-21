# Sistema de Trazabilidad para Producción de Panela

Aplicación móvil multiplataforma (Android/iOS) para el registro digital de trazabilidad en la cadena productiva de panela artesanal. Desarrollada para las cooperativas **NORANDINO** y **CAES** (Piura, Perú).

## Tecnologías

- **Flutter / Dart** — app móvil multiplataforma
- **Supabase** — backend (PostgreSQL 17, Auth, Edge Functions, RLS)
- **Riverpod** — gestión de estado
- **Drift / SQLite** — base de datos local para modo offline
- **GoRouter** — navegación

## Funcionalidades principales

- Registro de lotes de producción (caña → panela) con geolocalización
- Controles de calidad: cloro, limpieza, plagas, ambiente, personal, mantenimiento, salud
- Kardex de salidas e inventario por lote
- Gestión de certificaciones (Orgánica, FLO, SPP, Naturland)
- Modo **offline-first**: funciona sin internet y sincroniza automáticamente
- Multi-cooperativa: un solo APK para NORANDINO y CAES

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.x
- [Supabase CLI](https://supabase.com/docs/guides/cli) (para base de datos local)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (requerido por Supabase local)

## Configuración

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd flutter
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

Copiar el archivo de ejemplo y completar los valores:

```bash
cp .env.example .env
```

Editar `.env` con los datos de tu proyecto Supabase:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
NORANDINO_ACCESS_CODE=codigo_norandino
CAES_ACCESS_CODE=codigo_caes
```

Los valores `SUPABASE_URL` y `SUPABASE_ANON_KEY` se obtienen desde el panel de Supabase en **Settings → API**.

### 4. Configurar la base de datos

Ver instrucciones completas en el repositorio de la base de datos.

**Entorno local:**
```bash
cd ../supabase/mi-proyecto
supabase start
supabase db reset
```

**Producción (Supabase Cloud):**
```bash
supabase link --project-ref <ID_DEL_PROYECTO>
supabase db push
# Ejecutar seed.sql manualmente desde el SQL Editor de Supabase Studio
```

## Ejecutar la app

**Modo desarrollo** (conecta a Supabase local):
```bash
flutter run
```

**Modo producción** (conecta a Supabase Cloud):
```bash
flutter run --dart-define=USE_LOCAL_SUPABASE=false
```

## Compilar APK

```bash
# Desde el directorio flutter/
.\build_apks.ps1
```

El APK generado se encuentra en `build/app/outputs/flutter-apk/app-release.apk`.

Un solo APK sirve para ambas cooperativas. El usuario selecciona su cooperativa la primera vez que abre la app ingresando el código de acceso correspondiente.

## Estructura del proyecto

```
lib/
├── core/        # Configuración, router, base de datos local, sincronización offline
├── models/      # Modelos de dominio
├── providers/   # Providers Riverpod
├── services/    # Lógica de negocio y comunicación con Supabase
├── screens/     # Pantallas
└── widgets/     # Componentes de UI reutilizables
```

## Variables de entorno

| Variable | Descripción |
|---|---|
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Clave anónima pública de Supabase |
| `NORANDINO_ACCESS_CODE` | Código de acceso cooperativa Norandino |
| `CAES_ACCESS_CODE` | Código de acceso cooperativa CAES |
