# Lumen Biblia

Aplicación Flutter offline-first para leer la Biblia, registrar el progreso,
tomar notas y estudiar pasajes con contexto.

## Plataformas

- Windows: primera beta.
- Android e iOS: interfaz mantenida desde el inicio; publicación móvil posterior.

## Desarrollo

Requisitos: Flutter estable, Visual Studio con C++ para Windows y Android Studio
con el SDK de Android.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Las integraciones remotas se configuran en tiempo de compilación, nunca dentro
del repositorio:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://example.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_example
```

Sin estas variables, la aplicación funciona en modo invitado y conserva los
datos localmente.

Al iniciar sesión, la cola local sincroniza progreso, favoritos, resaltados,
notas y meta diaria con Supabase. El esquema reproducible y sus políticas RLS
están en `supabase/migrations/202607160001_initial.sql`.

## Integración continua

- GitHub Actions valida análisis, tests, APK Android y build Windows.
- Codemagic compila iOS sin firma. Para activarlo, conecta este repositorio en
  Codemagic y selecciona `codemagic.yaml`.

## Contenido bíblico

El desarrollo usa Reina-Valera 1909, publicada como dominio público por
[eBible.org](https://ebible.org/spaRV1909/copyright.htm). RVR1960 no se incluirá
sin una licencia explícita de distribución offline.
