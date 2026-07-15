---
name: verify
description: Build, install y verificación manual de colorblindapp en el simulador de iOS (taps con idb, capturas). Usar tras implementar o modificar una feature, antes de dar por cerrado un hito.
context: fork
agent: general-purpose
allowed-tools: Bash(xcodebuild:*), Bash(xcrun:*), Bash(idb:*), Bash(sips:*), Bash(git:*), Read
---

# Verificar colorblindapp en el simulador

App iOS SwiftUI (proyecto `colorblindapp.xcodeproj`, bundle id `com.admist.colorblindapp`).

Este skill corre en un subagente aislado (no ve el resto de la conversación), así que el build log completo, las capturas y los taps de `idb` no consumen contexto de la conversación principal — solo el resumen final que devuelvas.

## Qué verificar

$ARGUMENTS

Si no se especifica nada arriba, usa como guía los cambios recientes:

```
!`git diff HEAD --stat`
!`git log -1 --format=%s`
```

Verifica el flujo relacionado con esos cambios (o el flujo más relevante si el diff está vacío/es un commit ya cerrado).

## Cómo reportar al terminar

Al final, devuelve solo un resumen conciso: qué se verificó, si pasó o falló, y cualquier problema encontrado con su pantalla/paso. No incluyas el build log completo ni ninguna captura en tu respuesta final — esos detalles se quedan en tu propio contexto.

## Requisitos del entorno

- Xcode está en `/Applications/Xcode-26.6.0.app` pero `xcode-select` apunta a CommandLineTools: exportar siempre `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer`.
- Para taps en el simulador usar `idb` (AppleScript/cliclick no tienen permisos de accesibilidad):
  - `idb-companion` vía Homebrew (`brew install facebook/fb/idb-companion`) — ya instalado.
  - Cliente: `python3 -m pip install --user fb-idb`; añadir al PATH: `export PATH="$PATH:$(python3 -m site --user-base)/bin"`.
  - `idb` necesita `DEVELOPER_DIR` exportado o no verá ningún target.

## Receta

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer
export PATH="$PATH:$(python3 -m site --user-base)/bin"
SIM=F4E8E923-CB33-4D03-ABFD-01860A8AC96C   # iPhone 17 Pro iOS 26.5; verificar con: xcrun simctl list devices available

xcrun simctl boot $SIM && xcrun simctl bootstatus $SIM -b >/dev/null   # "Data Migration Failed" es inofensivo; comprobar estado Booted
xcodebuild build -project colorblindapp.xcodeproj -scheme colorblindapp \
  -destination "id=$SIM" -derivedDataPath <scratch>/dd -quiet > <scratch>/build.log 2>&1 \
  || grep -E "error:|BUILD FAILED" <scratch>/build.log   # solo muestra el log si algo falla
xcrun simctl install $SIM <scratch>/dd/Build/Products/Debug-iphonesimulator/colorblindapp.app
xcrun simctl launch $SIM com.admist.colorblindapp

idb ui tap <x> <y> --udid $SIM             # coordenadas en puntos (iPhone 17 Pro: 402x874 pt; px/3)
xcrun simctl io $SIM screenshot out.png    # capturas: 1206x2622 px
sips -Z 500 out.png --out out_small.png    # reescalar antes de verla: una captura a tamaño completo gasta muchos más tokens de los necesarios para juzgar una pantalla
xcrun simctl terminate $SIM com.admist.colorblindapp   # para probar persistencia
```

Ver siempre `out_small.png` (con `Read`), no `out.png`, salvo que necesites leer texto pequeño con detalle.

## Flujos que merece la pena recorrer

- Onboarding: bienvenida → "Ya sé mi tipo, elegirlo manualmente" → seleccionar tipo → Continuar → aparece el TabView.
- Persistencia: terminate + launch → debe ir directo al TabView sin onboarding.
- Ajustes → "Reiniciar onboarding" → confirmar → vuelve a la bienvenida.
- Para resetear estado del todo: `xcrun simctl uninstall $SIM com.admist.colorblindapp`.

## Gotchas

- El aviso `IDERunDestination: Supported platforms ... is empty` de xcodebuild es ruido, no un error.
- El build tiene `MemberImportVisibility` activado: cada archivo debe importar explícitamente los módulos que usa (p. ej. `import SwiftData` también en previews).
- El diálogo de confirmación de "Reiniciar onboarding" se presenta como popover anclado al Form, no como sheet inferior.
- `idb ui tap` sobre un `Toggle` de SwiftUI no registra el cambio con una pulsación corta por defecto; usar `idb ui tap <x> <y> --duration 0.2 --udid $SIM`. Botones, filas de lista y tab bar sí responden a un tap simple.
