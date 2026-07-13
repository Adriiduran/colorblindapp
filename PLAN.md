# Plan de desarrollo — App multiusos para personas daltónicas

## Visión

Una "navaja suiza" para personas con daltonismo: la app identifica el tipo de daltonismo del usuario mediante un test de onboarding, le permite escanear colores del mundo real con la cámara, y le ayuda a vestirse combinando la ropa de su armario virtual según reglas de colorimetría.

**Stack técnico:** SwiftUI + Swift, iOS 17+, arquitectura MVVM. Persistencia con SwiftData. Cámara con AVFoundation. Recorte de prendas con Vision (`VNGenerateForegroundInstanceMaskRequest`, el mismo motor de "levantar sujeto" de Fotos).

---

## FASE 1 — Onboarding + Escáner de color

> Esta fase se completa entera (diseñada, implementada y pulida) antes de empezar la Fase 2.

### 1.1 Onboarding: test de daltonismo

**Objetivo:** detectar el tipo de daltonismo del usuario y guardarlo como perfil, porque condiciona el resto de la app (qué colores confunde, qué avisos mostrar, cómo nombrar colores de forma útil).

- **Pantallas de bienvenida** (2-3): qué hace la app y por qué el test es importante.
- **Test tipo Ishihara**: láminas con números/formas ocultos en patrones de puntos. Con 10-15 láminas bien elegidas se puede distinguir entre:
  - *Protanopia / protanomalía* (rojo)
  - *Deuteranopia / deuteranomalía* (verde) — la más común
  - *Tritanopia / tritanomalía* (azul-amarillo) — necesita láminas específicas
  - *Visión normal* (la app sigue siendo útil, p. ej. el armario)
- **Resultado**: pantalla explicando el tipo detectado en lenguaje llano ("confundes rojos y verdes, sobre todo los apagados"), con disclaimer claro de que **no es un diagnóstico médico**.
- El perfil se guarda localmente y se puede repetir el test o cambiarlo a mano desde Ajustes.
- Opción "saltar test" eligiendo el tipo manualmente (mucha gente ya sabe cuál tiene).

**Detalles técnicos:**
- Las láminas van como assets en el bundle (hay sets de Ishihara de dominio público; para tritán, láminas tipo HRR o generadas).
- Modelo `UserProfile` en SwiftData: tipo de daltonismo, severidad aproximada, fecha del test.

### 1.2 Escáner de color con cámara

**Objetivo:** apuntar la cámara a cualquier cosa y saber qué color es, expresado en tres niveles:

1. **Hex** — `#6B8E23`
2. **Color básico** — "Verde"
3. **Nombre descriptivo** — "Verde oliva"

**Diseño de la función:**
- Vista de cámara a pantalla completa con una **retícula central** que marca el punto muestreado.
- Panel inferior con los tres valores del color, siempre visibles y actualizados en tiempo real.
- **Botón de congelar/capturar** para inspeccionar sin mantener el pulso, y poder tocar otros puntos de la imagen congelada.
- **Historial de colores escaneados** (los últimos N), con opción de guardar favoritos.
- Extra de alto valor para el público objetivo: **aviso de confusión** — si el color escaneado es de los que el perfil del usuario confunde (p. ej. un rojo apagado para un deután), mostrar una nota tipo "este color podría parecerte marrón/verde".

**Detalles técnicos:**
- `AVCaptureSession` con salida de vídeo; se muestrea una región pequeña (p. ej. 9×9 px) alrededor del centro y se promedia para estabilizar la lectura.
- Suavizado temporal (media móvil) para que el valor no "baile".
- Conversión RGB → HSL/Lab para clasificar:
  - **Color básico**: clasificación por rangos de tono/saturación/luminosidad (12-15 categorías: rojo, naranja, amarillo, verde, azul, morado, rosa, marrón, gris, negro, blanco…).
  - **Nombre descriptivo**: diccionario local de ~1.500 colores con nombre (hay datasets libres tipo *color-names*); se busca el más cercano por distancia en espacio Lab (ΔE), que es la métrica perceptualmente correcta.
- Todo funciona **offline** — sin llamadas de red.
- Permiso de cámara con pantalla previa explicando el porqué.

### 1.3 Estructura de la app en Fase 1

- `TabView` con: **Escáner** | **Armario** (placeholder "próximamente" o oculto) | **Ajustes**.
- Ajustes: ver/repetir test, cambiar tipo manualmente, gestión de historial.

### 1.4 Criterios para dar la Fase 1 por cerrada

- [ ] Onboarding completo con test, resultado y opción de saltar.
- [ ] Escáner estable en tiempo real con los 3 formatos de color.
- [ ] Historial + favoritos persistidos.
- [ ] Avisos de confusión según perfil.
- [ ] Probado en dispositivo real con distintas condiciones de luz.

---

## FASE 2 — Armario virtual + generador de outfits

> Empieza solo cuando la Fase 1 esté terminada y pulida.

### 2.1 Armario virtual

**Objetivo:** el usuario fotografía o sube imágenes de su ropa y la app construye un catálogo de prendas con su color dominante ya analizado.

- **Añadir prenda**: desde cámara o galería (`PhotosPicker`).
- **Recorte automático** de la prenda con Vision (segmentación de sujeto) para aislarla del fondo — clave para que el análisis de color no se contamine con el fondo.
- **Extracción del color dominante** de la prenda (clustering k-means sobre los píxeles de la máscara; guardar 1 color dominante + 1-2 secundarios para prendas estampadas).
- **Ficha de prenda**: foto recortada, categoría (camiseta, camisa, pantalón, falda, zapatos, chaqueta, accesorio…), color detectado (editable por el usuario — importante: el usuario es daltónico y debe poder confiar en el valor, pero también corregir si la foto salió mal), etiquetas opcionales (formal/casual, verano/invierno).
- **Vista de armario**: grid filtrable por categoría y color.

### 2.2 Generador de outfits

**Objetivo:** el usuario elige una prenda "ancla" y la app propone combinaciones con lo que hay en el armario, siguiendo reglas de colorimetría.

**Motor de combinación (reglas sobre el círculo cromático, en espacio HSL/Lab):**
- **Neutros** (blanco, negro, gris, beige, azul marino, denim) combinan con casi todo → puntuación base alta.
- **Monocromático**: mismo tono, distinta luminosidad/saturación.
- **Análogos**: tonos adyacentes (±30-40°).
- **Complementarios**: tonos opuestos (~180°), con moderación (una prenda de acento, no dos).
- **Tríada / complementario dividido** como reglas avanzadas.
- Penalizaciones: dos prendas saturadas que compiten, choques conocidos (rojo+rosa fucsia, marrón+negro según contexto…).
- Cada outfit propuesto lleva una **puntuación y una explicación en texto** ("combina porque el beige es neutro y el azul marino contrasta suave con tu camiseta mostaza") — para un usuario daltónico la explicación es tan importante como la propuesta.

**Flujo:**
1. Usuario elige prenda ancla (o "sorpréndeme").
2. La app compone outfits completos (parte de arriba + parte de abajo + calzado, + capa exterior opcional) puntuando cada combinación.
3. Se muestran las 3-5 mejores con visualización de las prendas juntas.
4. Opción de guardar outfits favoritos y marcarlos como "usado hoy".

### 2.3 Criterios para cerrar la Fase 2

- [ ] Alta de prendas con recorte y color automático + edición manual.
- [ ] Armario filtrable y persistente.
- [ ] Generador con explicaciones y guardado de outfits.
- [ ] Probado con un armario real de 30+ prendas.

---

## Monetización

Modelo recomendado: **freemium con suscripción** (es el estándar en apps de utilidad iOS y encaja con el corte natural entre las dos fases).

### Opción A — Freemium + suscripción (recomendada)

**Gratis:** test de daltonismo completo + escáner básico (los 3 formatos de color, historial limitado a 10).
**Premium (suscripción mensual/anual, con prueba gratuita de 7 días):**
- Armario virtual ilimitado y generador de outfits (la función estrella de pago).
- Historial y favoritos ilimitados en el escáner.
- Avisos de confusión personalizados y funciones futuras (filtros de accesibilidad, etc.).

*Racional:* el escáner gratis genera descargas, reseñas y confianza; el armario es el hábito diario por el que se paga. Precio orientativo: 2,99 €/mes o 19,99 €/año, con RevenueCat o StoreKit 2 para gestionarlo.

### Opción B — Compra única "Pro"

Un pago de 9,99-14,99 € que desbloquea todo. Menos ingresos recurrentes pero muy bien recibida por la comunidad de accesibilidad (sensible a las suscripciones). Puede convivir con la A como "lifetime unlock" a precio alto (39,99 €).

### Opción C — Ingresos complementarios

- **Afiliación de moda**: cuando el generador detecte huecos en el armario ("te falta un pantalón neutro"), sugerir prendas con enlaces de afiliado (Amazon Moda, ASOS). Potencial alto a largo plazo, requiere volumen de usuarios.
- **B2B/licencias**: el motor de test + nombrado de colores podría licenciarse a e-commerce de moda para accesibilidad. A explorar mucho más adelante.
- **Anuncios**: desaconsejados — dañan la experiencia en una app de accesibilidad y el CPM no compensa en una app de nicho.

**Decisión de implementación:** montar el paywall al final de la Fase 2 (cuando exista la función premium), pero diseñar desde la Fase 1 con la separación gratis/premium en mente (p. ej. límite de historial ya definido en el modelo de datos).

---

## Sugerencias futuras (NO prioritarias — fuera del plan actual)

Ideas alineadas con la visión de "navaja multiusos" para incorporar después de las Fases 1 y 2:

1. **Filtros de corrección/simulación en tiempo real**: aplicar filtros tipo daltonización sobre la cámara para realzar colores que el usuario confunde; y el inverso (simular cómo ve un daltónico) como herramienta para familiares/diseñadores.
2. **Escáner de imágenes de la galería**: analizar colores de capturas de pantalla o fotos ya hechas, no solo cámara en vivo (útil para gráficos, mapas, webs).
3. **Modo "semáforo de madurez"**: apuntar a fruta (plátanos, tomates, aguacates) y que la app diga el punto de maduración — caso de uso real muy citado por personas daltónicas.
4. **Detección de estado en LEDs/indicadores**: identificar si un LED o indicador está en rojo/verde/ámbar (routers, cargadores, electrodomésticos).
5. **Widget y App Intents/Siri**: "Oye Siri, ¿de qué color es esto?" y accesos rápidos al escáner desde la pantalla de bloqueo.
6. **Outfit del día con el tiempo**: cruzar el generador de outfits con la previsión meteorológica.
7. **Compartir armario / segunda opinión**: enviar un outfit a un amigo o pareja para validación humana rápida.
8. **Etiquetado por IA de las prendas**: clasificar automáticamente categoría y estilo de la prenda con un modelo de visión (Core ML o API), en vez de que el usuario lo elija a mano.
9. **Apple Watch**: escáner rápido de color desde la muñeca.
10. **Historial clínico del test**: repetir el test periódicamente y graficar la evolución (el daltonismo adquirido puede cambiar; útil también para llevarle datos al oftalmólogo).
11. **Localización**: nombres de color descriptivos en varios idiomas (el dataset de nombres debe traducirse con cuidado, no literalmente).

---

## Orden de trabajo resumido

| Hito | Contenido |
|------|-----------|
| 1 | Esqueleto de app: TabView, navegación, modelos SwiftData, perfil de usuario |
| 2 | Onboarding + test de daltonismo + pantalla de resultado |
| 3 | Escáner: cámara en vivo, muestreo y conversión de color |
| 4 | Escáner: nombres descriptivos (dataset + ΔE), historial, favoritos, avisos de confusión |
| 5 | Pulido Fase 1 + pruebas en dispositivo → **posible lanzamiento v1.0 solo con escáner** |
| 6 | Armario: alta de prendas, recorte con Vision, extracción de color |
| 7 | Armario: catálogo, categorías, edición |
| 8 | Generador de outfits: motor de colorimetría + explicaciones |
| 9 | Paywall + suscripción (StoreKit 2 / RevenueCat) → **lanzamiento v2.0** |
