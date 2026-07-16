# Publicación

## Windows

```powershell
flutter build windows --release
.\scripts\package_windows.ps1
```

Esto genera `build/release/LumenBiblia.msix`. El manifiesto usa provisionalmente
`CN=17Yerdna`; antes de distribuir, hay que reemplazarlo por el Publisher del
certificado o de Microsoft Store y firmar el MSIX. No se guardan certificados ni
contraseñas en el repositorio.

La carpeta `build/windows/x64/runner/Release` también es una distribución
portable: debe entregarse completa, no solo el ejecutable.

## Android

```powershell
flutter build apk --release
flutter build appbundle --release
```

El APK sirve para pruebas directas. El AAB requiere un keystore privado de
producción antes de subirlo a Google Play; la configuración actual usa la firma
de desarrollo y no debe publicarse.

## iOS

`codemagic.yaml` ejecuta análisis, pruebas y un build Release sin firma. Instalar
en un iPhone o publicar por TestFlight requiere Apple Developer, certificados y
un perfil de aprovisionamiento.

## Servicios remotos

Antes de una beta conectada:

```powershell
supabase db push
supabase secrets set OPENAI_API_KEY=tu_clave
supabase functions deploy explain-passage delete-account
```

RVR1960 solo puede sustituir al texto de desarrollo cuando exista una licencia
explícita para distribución offline.
