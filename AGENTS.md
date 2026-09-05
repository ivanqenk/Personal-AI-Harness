# AGENTS.md

Este repositorio trabaja con **Spec Driven Development (SDD)**. No escribas código directamente
sobre una feature nueva sin pasar antes por el flujo descrito aquí.

## Principio central

El bug más caro no es el que se escribe, es el que se escribe sin entender el problema o el
código existente. Por eso este flujo no empieza en "escribe código", empieza en "entiende
antes de tocar nada" — y eso es agnóstico de lenguaje: la lógica de negocio, las
convenciones y los riesgos se leen en cualquier stack. Las seis fases de abajo (exploración,
clarificación, spec, implementación incremental, verificación, revisión) existen para
proteger ese principio, no como burocracia.

Fichero portable: `CLAUDE.md`, y el equivalente para otras CLIs (Codex, Cursor, opencode...),
apuntan aquí en vez de duplicar estas instrucciones. Edita solo este fichero.

## Antes de nada: la constitución

Lee `docs/constitution.md`. Son los principios innegociables del proyecto (qué no se
transige nunca: seguridad, estilo, alcance, etc.). Ningún agente puede proponer una spec,
un diseño o una implementación que la contradiga.

## Rol de arranque

Al empezar cualquier sesión, actúa como el agente **leader** (ver `.claude/agents/leader.md`).
El leader es el único que decide si toca especificar, implementar o revisar, en función del
estado guardado en `tasks.json`.

Si el usuario te pide "implementa la siguiente tarea", "continúa", "sigue con SDD" o algo
equivalente: lee `tasks.json`, identifica la **primera tarea que no esté `done`, en el orden
en que aparecen en el fichero**, y sigue el protocolo del leader. No hay campo de prioridad:
el orden del array es la prioridad. Si quieres adelantar algo, muévelo arriba o pídelo por
nombre ("retoma <feature>").

## Dónde está todo

- `tasks.json` — lista maestra de tareas/features y su estado (memoria de alto nivel del leader).
- `specs/<feature>/` — para cada feature: `requirements.md`, `design.md`, `tasks.md`.
  Formato descrito en `specs/SPECS_FORMAT.md`.
- `.claude/agents/` — subagentes: `leader`, `spec-author`, `implementer`, `reviewer`.
- `rules/` — convenciones que TODOS los agentes deben leer y respetar:
  - `rules/global-conventions.md`
  - `rules/backend-instructions.md`
  - `rules/frontend-instructions.md`
- `progress/` — notas de trabajo en curso de cada agente (contexto externo, no memoria del chat).
- `history.md` — histórico append-only de features completadas.
- `init.sh` — script obligatorio para verificar entorno y ejecutar tests. Todos los agentes deben
  ejecutarlo antes de darse por terminados.

## Regla de oro

Nunca implementes código de una feature nueva si no existe ya `specs/<feature>/tasks.md`
aprobado por el humano (estado `spec_ready` o posterior en `tasks.json`). Si no existe, lanza
primero al `spec-author`.

Única excepción: tareas marcadas `"use_sdd": false` en `tasks.json` — cambios triviales y sin
ambigüedad (un typo, un parámetro nuevo) que van directas al `implementer` con una descripción
de una línea. En caso de duda, usa SDD completo.

## Principio de cambio (spec-first)

Si una feature ya está `done` y hay que cambiar su comportamiento, el cambio empieza
**siempre** editando `specs/<feature>/requirements.md` (y `design.md` si aplica), nunca
tocando el código directamente. Trátalo como una spec nueva que vuelve a `pending` con una
nota indicando qué requisito cambia y por qué.
