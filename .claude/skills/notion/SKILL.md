---
name: notion
description: Lee o actualiza el registro de funcionalidades/plan del proyecto en la base de datos de Notion. Usar para consultar el roadmap o reflejar una feature/idea recién implementada o hablada, en vez de llamar a las herramientas mcp__notion__* directamente desde la conversación principal.
context: fork
agent: general-purpose
allowed-tools: mcp__notion__API-post-page, mcp__notion__API-patch-page, mcp__notion__API-post-search, mcp__notion__API-retrieve-a-page, mcp__notion__API-retrieve-page-markdown, mcp__notion__API-get-block-children, mcp__notion__API-patch-block-children, mcp__notion__API-delete-a-block, mcp__notion__API-retrieve-a-block, Bash(jq:*), Bash(python3:*), Write
---

# Registro de funcionalidades de colorblindapp en Notion

Este skill corre en un subagente aislado (no ve el resto de la conversación): los resultados de búsquedas o páginas de Notion (pueden ser grandes — la base tiene ~37 filas) se quedan en su propio contexto, no en el de la conversación principal. Solo el resumen final que devuelvas cuenta para la conversación principal.

## Qué hacer

$ARGUMENTS

Si no se especifica nada arriba, asume una consulta de solo lectura del estado actual del plan.

## Dónde vive el registro

Página de Notion **"Colorblind App — Registro de funcionalidades"**: https://app.notion.com/p/COLORBLINDAPP-39e5244717a780fe966cd05d36a12ca6

Es una **base de datos incrustada** (id `39e52447-17a7-80be-b680-cadb5bda9398`) con propiedades:
- **Tarea** (title)
- **Estado** (Hecho / Pendiente / Idea — no existe "En progreso")
- **Tipo** (Escáner / Armario / Monetización / Pulido / Dev-QA / Backlog)
- **Prioridad** (Alta / Media / Baja)
- **Descripción** (rich_text)

## Cómo leer

Los endpoints de *data source* (`create-a-data-source`, `update-a-data-source`, `query-a-data-source`, `retrieve-a-data-source`) están rotos en este entorno (API clásica de Notion, devuelven `invalid_request_url`) — no se puede consultar la base de datos por su data source id.

Para listar filas: `mcp__notion__API-post-search` con `filter {property: "object", value: "page"}`, y filtrar el resultado por `parent.database_id == "39e52447-17a7-80be-b680-cadb5bda9398"`. El resultado es grande: vuélcalo a un archivo en tu scratchpad y procésalo con `jq`/`python3` en vez de leerlo entero de golpe.

## Cómo escribir

- **Nueva fila** (feature hecha o idea/plan futuro): `mcp__notion__API-post-page` con `parent {type: "database_id", database_id: "39e52447-17a7-80be-b680-cadb5bda9398"}` y las propiedades por nombre.
- **Editar una fila existente** (p. ej. marcar Estado = "Hecho"): primero localízala (ver "Cómo leer"), luego `mcp__notion__API-patch-page` con el `page_id` de esa fila.

## Cómo reportar al terminar

Devuelve solo un resumen conciso: qué filas leíste/creaste/editaste, sus valores relevantes (Tarea, Estado, Tipo), y cualquier problema encontrado. No incluyas el JSON completo de ninguna respuesta de Notion en tu mensaje final — eso se queda en tu propio contexto.
