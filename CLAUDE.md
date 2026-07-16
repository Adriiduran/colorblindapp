# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es

App iOS (SwiftUI + SwiftData, iOS 17+, MVVM) para personas daltónicas: test de daltonismo en el onboarding, escáner de color con la cámara, y armario virtual con generador de outfits por colorimetría. Todo funciona offline (Vision on-device, sin llamadas de red). Bilingüe es/en vía String Catalog (`Localizable.xcstrings`); el idioma de desarrollo es el español y los textos del código son las claves.

El plan de desarrollo (fases, hitos, backlog) vive en Notion, no en el repo — ver la memoria `project-plan-in-notion`. Al cerrar cada hito: verificar en el simulador y proponer el mensaje de commit; commitea el usuario, no Claude.

## Build y verificación

- No hay target de tests unitarios; la verificación es manual en el simulador. Usar el skill del proyecto **`verify`** (`.claude/skills/verify/SKILL.md`), que contiene la receta completa (build, install, launch, taps con `idb`, capturas) y los gotchas del entorno.
- Crítico: `xcode-select` apunta a CommandLineTools; exportar siempre `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer` antes de cualquier `xcodebuild`/`simctl`.
- Build rápido:
  ```bash
  env DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer \
    xcodebuild build -project colorblindapp.xcodeproj -scheme colorblindapp \
    -destination 'id=<sim-udid>' -derivedDataPath <scratch>/dd -quiet
  ```
- `MemberImportVisibility` está activado: cada archivo debe importar explícitamente lo que usa (p. ej. `import SwiftData` también en previews).
- Vision (`VNClassifyImageRequest`, segmentación) no funciona de verdad en el simulador — siempre cae al fallback; solo verificable en dispositivo real.
- `colorblindapp/Tests/` contiene **imágenes de prueba** para el benchmark del analizador, no tests de código.

## Arquitectura

Flujo raíz: `colorblindappApp` crea `PurchaseManager` (en `@Environment`) y el `ModelContainer` de SwiftData → `RootView` muestra `OnboardingView` si no hay `UserProfile`, o `MainTabView` (Escáner · Armario · Ajustes) si lo hay.

- **`Models/`** — modelos SwiftData (`UserProfile`, `SavedColor`, `Garment`, `Outfit`) y los motores puros:
  - `GarmentAnalyzer` — pipeline de análisis de prenda: segmentación Vision → erosión de máscara → clustering k-means en espacio Lab → dominante por mediana y peso×croma, con rechazo de sombras/brillos. También estima la categoría con `VNClassifyImageRequest` (mapeo de etiquetas genéricas → `GarmentCategory`). Incluye `Benchmark` (ver abajo).
  - `OutfitEngine` — reglas de colorimetría (neutros, monocromático, análogos, complementarios) que puntúan combinaciones y generan la explicación en texto.
  - `ColorNamer` / `ColorCatalog` — nombre básico + descriptivo del color por distancia ΔE en Lab; nombres bilingües curados.
  - `CVDSimulator`, `ColorVisionTest`, `ColorVisionType` — simulación de daltonismo y el test tipo Ishihara.
- **`Support/`** — `CameraColorSampler` (AVFoundation, muestreo y suavizado del escáner), `LinearRGB` (conversiones de espacio de color), `PurchaseManager` (StoreKit 2).
- **`Views/`** — SwiftUI por feature (Onboarding, Test, Scanner, Wardrobe, Outfits, Paywall, Settings). `ScannerModel` es el view-model del escáner.

## Freemium (afecta a casi cualquier feature nueva)

`PurchaseManager` es la única fuente de verdad del acceso: gratis tiene límite de armario (`freeWardrobeLimit`), límite de historial del escáner (`freeHistoryLimit`) y una generación de outfits cada 7 días (`lastFreeOutfitDate`, cata semanal); premium (mensual/anual, trial de 7 días, `Configuration.storekit` en la raíz) lo desbloquea todo. Al añadir funcionalidad, decidir de qué lado del paywall cae.

## Convenciones

- Código y comentarios en español.
- Commits: los hace **el usuario**, nunca Claude. Al cerrar un hito o un cambio significativo, proponer el mensaje en un bloque de código listo para copiar, con formato [Conventional Commits](https://www.conventionalcommits.org/) **en inglés** (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`…), asunto en imperativo y sin punto final.
- Localización: nunca pasar `String` por parámetros de helpers de vista para texto visible — rompe la extracción del String Catalog; usar `LocalizedStringKey` (ver memoria `swiftui-localization-string-vs-localizedstringkey`).
- Afinado del color: no iterar a ojo — usar `GarmentAnalyzerBenchmarkView` (Ajustes, solo DEBUG), que corre `GarmentAnalyzer.Benchmark` y reporta acierto de categoría y ΔE medio.
