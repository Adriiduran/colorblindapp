# Verificar colorblindapp en el simulador

App iOS SwiftUI (proyecto `colorblindapp.xcodeproj`, bundle id `com.admist.colorblindapp`).

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

xcrun simctl boot $SIM && xcrun simctl bootstatus $SIM -b   # "Data Migration Failed" es inofensivo; comprobar estado Booted
xcodebuild build -project colorblindapp.xcodeproj -scheme colorblindapp \
  -destination "id=$SIM" -derivedDataPath <scratch>/dd -quiet
xcrun simctl install $SIM <scratch>/dd/Build/Products/Debug-iphonesimulator/colorblindapp.app
xcrun simctl launch $SIM com.admist.colorblindapp

idb ui tap <x> <y> --udid $SIM             # coordenadas en puntos (iPhone 17 Pro: 402x874 pt; px/3)
xcrun simctl io $SIM screenshot out.png    # capturas: 1206x2622 px
xcrun simctl terminate $SIM com.admist.colorblindapp   # para probar persistencia
```

## Flujos que merece la pena recorrer

- Onboarding: bienvenida → "Ya sé mi tipo, elegirlo manualmente" → seleccionar tipo → Continuar → aparece el TabView.
- Persistencia: terminate + launch → debe ir directo al TabView sin onboarding.
- Ajustes → "Reiniciar onboarding" → confirmar → vuelve a la bienvenida.
- Para resetear estado del todo: `xcrun simctl uninstall $SIM com.admist.colorblindapp`.

## Gotchas

- El aviso `IDERunDestination: Supported platforms ... is empty` de xcodebuild es ruido, no un error.
- El build tiene `MemberImportVisibility` activado: cada archivo debe importar explícitamente los módulos que usa (p. ej. `import SwiftData` también en previews).
- El diálogo de confirmación de "Reiniciar onboarding" se presenta como popover anclado al Form, no como sheet inferior.
