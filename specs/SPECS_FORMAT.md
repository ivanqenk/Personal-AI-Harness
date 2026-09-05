# Formato de especificaciones

Cada feature vive en `specs/<feature-slug>/` con exactamente tres ficheros. Usa
`specs/_template/` como punto de partida.

## 1. `requirements.md` — notación EARS

EARS (Easy Approach to Requirements Syntax) obliga a que cada requisito sea concreto y
verificable, para poder traducirlo 1:1 a un test. Patrones más comunes:

- **Ubicuo**: `El sistema debe <comportamiento siempre activo>.`
- **Evento**: `Cuando <evento/trigger>, el sistema debe <respuesta>.`
- **Estado**: `Mientras <estado>, el sistema debe <comportamiento>.`
- **Opcional**: `Donde <feature/config activada>, el sistema debe <comportamiento>.`
- **No deseado**: `Si <condición de error>, entonces el sistema debe <manejo del error>.`

Ejemplo: *"Cuando el usuario ejecuta `notas list` sin pasar `--limit`, el sistema debe
imprimir como máximo 5 notas ordenadas por fecha descendente."*

`requirements.md` debe incluir siempre:
- Contexto y usuarios.
- Historias de usuario (opcional pero recomendado para features con interacción humana).
- Lista de requisitos funcionales en formato EARS, numerados (RF-1, RF-2...).
- **Casos límite**: entradas vacías, valores extremos, errores, concurrencia, permisos...
- Sección **"Fuera de alcance"**: qué NO se va a construir (evita que la IA lo invente).
- **Criterios de finalización**: cómo se sabe objetivamente que la feature está terminada.
- Sección **"Preguntas abiertas"** (si las hay) para que el humano decida antes de aprobar.

## Paso intermedio: Clarificación

Antes de pasar de `requirements.md` a `design.md`, el spec-author relee el documento en
modo QA adversarial buscando ambigüedad, contradicciones o huecos, y mueve cualquier duda
real a "Preguntas abiertas" en vez de asumir una respuesta. Este paso no genera un fichero
nuevo — es una revisión obligatoria antes de diseñar.

## 2. `design.md` — decisiones técnicas

- Ficheros/módulos que se van a crear o modificar (rutas concretas).
- Ficheros que explícitamente NO se deben tocar.
- Clases, funciones, componentes o endpoints nuevos, con su firma si aplica.
- Cómo encaja con la arquitectura y convenciones ya existentes en el repo.

Si una decisión técnica no se especifica aquí, el implementer la va a inventar — evita
dejar huecos.

## 3. `tasks.md` — desglose atómico

Lista ordenada `T1, T2, T3...`. Cada tarea:
- Es casi un prompt exacto y autocontenido para el implementer.
- Tiene una condición de entrega clara ("hecho cuando...").
- Se marca `[ ]` → `[x]` a medida que se completa.

## Estado en `tasks.json`

El ciclo de vida de una feature (`pending → spec_ready → in_progress → done`) se controla
desde `tasks.json`, no desde estos ficheros. Ver `.claude/agents/leader.md`.

## Constitución

Ninguna spec puede contradecir `docs/constitution.md`. Si una spec necesita romper un
principio de la constitución, eso se decide y se anota explícitamente en la constitución
primero (es un cambio de proyecto, no de feature), nunca al revés.

## Cambios sobre features ya terminadas

Toda modificación de una feature `done` empieza editando su `requirements.md` (principio
de "spec-first"). Nunca se toca el código de una feature completada sin pasar antes por su
spec.
