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

Lo portable es el **proceso**, no la orquestación: `.claude/agents/` y el hook de
`.claude/settings.json` solo los entiende Claude Code. En otra CLI tendrás las mismas seis
fases y los mismos ficheros de contexto, pero el reparto en subagentes y el gate automático
tendrás que reproducirlos con lo que esa herramienta ofrezca.

## Antes de nada: la constitución

Lee `docs/constitution.md`. Son los principios innegociables del proyecto (qué no se
transige nunca: seguridad, estilo, alcance, etc.). Ningún agente puede proponer una spec,
un diseño o una implementación que la contradiga.

## Rol de arranque

Al empezar cualquier sesión, **el hilo principal actúa como leader** (manual en
`.claude/agents/leader.md`). El leader es el único que decide si toca especificar,
implementar o revisar, en función del estado guardado en `tasks.json`.

El leader no es un subagente y no se delega en él: un subagente no puede lanzar otros
subagentes, así que un leader delegado se quedaría sin poder llamar a `spec-author`,
`implementer` ni `reviewer`. Los tres sí son subagentes, y los lanza el hilo principal.

Si el usuario te pide "implementa la siguiente tarea", "continúa", "sigue con SDD" o algo
equivalente: lee `tasks.json`, identifica la **primera tarea que no esté `done`, en el orden
en que aparecen en el fichero**, y sigue el protocolo del leader. No hay campo de prioridad:
el orden del array es la prioridad. Si quieres adelantar algo, muévelo arriba o pídelo por
nombre ("retoma <feature>").

## Dónde está todo

- `tasks.json` — lista maestra de tareas/features y su estado (memoria de alto nivel del leader).
- `specs/<feature>/` — para cada feature: `requirements.md`, `design.md`, `tasks.md`.
  Formato descrito en `specs/SPECS_FORMAT.md`.
- `.claude/agents/` — subagentes del flujo: `spec-author`, `implementer`, `reviewer`.
  (`leader.md` está ahí también, pero como manual del rol del hilo principal, no como agente
  al que delegar.) Más los **consultores**, que no forman parte de la máquina de estados:
  `aws` (arquitectura, DevOps, observabilidad y costos en AWS).
- `rules/` — convenciones que TODOS los agentes deben leer y respetar:
  - `rules/global-conventions.md`
  - `rules/backend-instructions.md`
  - `rules/frontend-instructions.md`
- `progress/` — notas de trabajo en curso de cada agente (contexto externo, no memoria del chat).
- `history.md` — histórico append-only de features completadas.
- `init.sh` — script obligatorio para verificar entorno y ejecutar tests. El `implementer` y el
  `reviewer` deben ejecutarlo antes de darse por terminados; el leader solo antes de mover una
  tarea a `in_progress` o `in_review`. Falla a propósito mientras no esté personalizado para el
  proyecto: un gate que aprueba sin ejecutar nada es peor que no tener gate.
- `.claude/settings.json` + `.claude/hooks/` — el gate automático que hace insaltable la regla de
  oro (ver abajo).

## Regla de oro

Nunca implementes código de una feature nueva si no existe ya `specs/<feature>/tasks.md`
**aprobado por el humano**, es decir con la tarea en `in_progress` o posterior en
`tasks.json`. `spec_ready` significa que la spec está escrita pero **todavía no aprobada**:
no basta. Si no existe spec, lanza primero al `spec-author`.

Única excepción: tareas marcadas `"use_sdd": false` en `tasks.json` — cambios triviales y sin
ambigüedad (un typo, un parámetro nuevo) que van directas al `implementer` con una descripción
de una línea. En caso de duda, usa SDD completo.

Esta regla no depende de que ningún agente se acuerde de ella: un hook `PreToolUse` bloquea
toda escritura sobre código de producción mientras no haya una tarea `in_progress` en
`tasks.json`. Los ficheros del arnés (`specs/`, `progress/`, `docs/`, `rules/`, `tasks.json`...)
se escriben siempre, porque son justo lo que hay que poder editar *antes* de tener una spec.
Si el hook bloquea algo, el arreglo es mover la tarea al estado que toca — nunca desactivar el
gate ni escribir el fichero por otra vía.

## Agentes consultores

`aws` no es una fase del flujo, y tampoco se invoca solo: **solo lo lanza el humano,
explícitamente y por su nombre**. Ningún agente lo llama por su cuenta porque el tema
parezca de AWS.

El leader puede sugerirlo en una línea cuando la feature toca infraestructura, pipelines,
permisos o costos, y el momento en que la sugerencia vale algo es **la fase de spec**: lo
que el especialista devuelva —servicios, compromisos, costo estimado, pasos de despliegue—
se escribe en `design.md` y se aprueba como cualquier otra decisión técnica. Consultarlo
con el código ya escrito llega tarde. Pero decidir si se consulta es tuyo.

Dos cosas que conviene tener claras:

- El `aws` nunca modifica la cuenta. Escribe Terraform, CDK y workflows de CI en local, y
  los comandos que despliegan te los entrega escritos para que los ejecutes tú.
- **El IaC es código de producción a efectos de este arnés.** El hook bloquea escribir un
  `.tf` igual que un `.py` si no hay una tarea `in_progress`. Un cambio de infraestructura
  pasa por spec como cualquier otro — que sea infraestructura no lo hace trivial, lo hace
  más caro de revertir.

## Estados de una tarea

`pending` → `needs_clarification` (si la spec topa con preguntas que solo el humano resuelve)
→ `spec_ready` → `in_progress` → `in_review` → `done`. Ninguno es opcional: el `status` por sí
solo debe bastar para saber en qué fase estás si la sesión se corta. El detalle de cada
transición está en `.claude/agents/leader.md`.

## Principio de cambio (spec-first)

Si una feature ya está `done` y hay que cambiar su comportamiento, el cambio empieza
**siempre** editando `specs/<feature>/requirements.md` (y `design.md` si aplica), nunca
tocando el código directamente. Trátalo como una spec nueva que vuelve a `pending` con una
nota indicando qué requisito cambia y por qué.
