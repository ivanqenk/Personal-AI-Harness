# Plan: Spec Driven Development (SDD) con Claude Code

Basado en dos enfoques:

1. **Método simplificado** (un solo `requirements.md` + `plan.md` generado por plan mode) —
   rápido, ideal para MVPs y proyectos individuales.
2. **Harness con subagentes** (leader / spec-author / implementer / reviewer, con
   `tasks.json` como memoria y `specs/<feature>/` como contexto externo curado) — más
   robusto, ideal para proyectos que van a vivir mucho tiempo o donde varias personas tocan
   el código.

Esta carpeta implementa la **opción 2**, adaptada a las primitivas reales de Claude Code
(`.claude/agents/` para subagentes) y con `AGENTS.md` como fuente de verdad portable, porque
es la que escala mejor y de la que puedes "bajar" fácilmente a la opción 1 cuando te sobre.
Abajo tienes las dos explicadas y cómo elegir entre ellas.

## Qué hay en esta carpeta

```
CLAUDE.md                     ← solo apunta a AGENTS.md (@AGENTS.md), lo carga Claude Code
AGENTS.md                     ← fuente de verdad portable (Claude Code, Codex, Cursor...)
docs/
  constitution.md             ← principios innegociables del proyecto (leer antes que nada)
.claude/agents/
  leader.md                   ← manual del rol leader, que asume el hilo principal
  spec-author.md              ← requirements.md → clarificación → design.md → tasks.md
  implementer.md              ← ejecuta tasks.md, contexto mínimo
  reviewer.md                 ← aprueba o rechaza contra la spec
  aws.md                      ← consultor: arquitectura, DevOps y costos en AWS
.claude/settings.json         ← registra el hook que hace insaltable la regla de oro
.claude/hooks/
  guard-spec-first.sh         ← bloquea escrituras en código si nada está in_progress
specs/
  SPECS_FORMAT.md              ← formato EARS + estructura de los 3 ficheros + clarificación
  _template/                   ← plantillas para copiar en cada feature nueva
rules/
  global-conventions.md        ← git, testing, human-in-the-loop
  backend-instructions.md      ← convenciones de backend (plantilla, personalizar)
  frontend-instructions.md     ← convenciones de frontend (plantilla, personalizar)
tasks.json                     ← lista de features y su estado (memoria del leader)
instincts.md                   ← correcciones repetidas, candidatas a promoverse a rules/
prompts.md                     ← chuleta con el prompt exacto de cada fase
progress/                      ← contexto de trabajo en curso, un fichero por feature
history.md                     ← histórico append-only de features completadas
init.sh                        ← script obligatorio: verificar entorno + correr tests
.gitignore.example             ← para uso personal (renómbralo); en equipo, commitea todo
```

## Agentes consultores

Además de los cuatro roles del flujo hay especialistas que **no son una fase**: se consultan
cuando hacen falta y su respuesta acaba escrita en `design.md`.

Hoy hay uno, `aws`: elige entre servicios, diseña VPCs, escribe y revisa
Terraform/CDK/CloudFormation, diseña pipelines de CI/CD y estrategias de rollback, lee logs,
monta observabilidad, audita IAM y estima costos. Nunca modifica la cuenta: los comandos que
despliegan te los entrega escritos para que los ejecutes vos.

**Solo se invoca explícitamente**: lo pedís vos por su nombre ("que lo mire el agente de
aws"). Ningún agente lo lanza solo. El leader como mucho te lo sugiere en una línea cuando la
feature toca infra, y el momento en que esa sugerencia vale algo es la fase de spec — con el
código escrito llega tarde. Y ojo: el IaC cuenta como código de producción, así que el hook
bloquea escribir un `.tf` igual que cualquier otro fichero si no hay una tarea `in_progress`.

Para añadir más especialistas (`security-reviewer`, `db-migrator`, lo que necesites), copiá
el patrón: un `.md` en `.claude/agents/` con su `description` diciendo cuándo invocarlo.

## Los dos gates automáticos

Casi todo el arnés son instrucciones en prosa, y una instrucción en prosa se puede olvidar.
Estas dos piezas no:

- **`init.sh`** falla mientras no lo personalices (`PROYECTO_CONFIGURADO=true`) o queden
  placeholders `<...>` en `rules/` o `docs/constitution.md`. Un `init.sh` que imprime "OK"
  sin ejecutar nada no es un gate: es confianza falsa, y el leader, el implementer y el
  reviewer estarían aprobando contra nada. También valida `tasks.json` y comprueba la
  trazabilidad RF→test.
- **El hook `PreToolUse`** (`.claude/settings.json` → `.claude/hooks/guard-spec-first.sh`)
  bloquea cualquier escritura sobre código de producción si no hay ninguna tarea
  `in_progress` en `tasks.json`. Los ficheros del arnés se escriben siempre. Si te bloquea,
  el arreglo es mover la tarea al estado que toca; para desactivarlo del todo:
  `SDD_GUARD=off claude`.

## Cómo instalarlo en cualquier proyecto (nuevo o existente)

> Versión paso a paso, con el ciclo de día a día incluido: ver [`GUIA_DE_USO.md`](GUIA_DE_USO.md).

1. Copia toda esta carpeta a la raíz de tu repo (o solo los ficheros que quieras: puedes
   empezar solo con `CLAUDE.md` + `.claude/agents/` + `tasks.json`).
2. Rellena `rules/global-conventions.md`, `rules/backend-instructions.md` y
   `rules/frontend-instructions.md` con las convenciones reales del proyecto — esto es lo
   más importante: si no defines aquí una decisión, la IA la va a inventar por ti.
3. Rellena `init.sh` con los comandos reales (instalar deps, lint, tests) de tu stack, pon
   `PROYECTO_CONFIGURADO=true` y `RUTAS_TESTS` con las rutas de tus tests, y comprueba que
   sigue siendo ejecutable (`chmod +x init.sh`): los agentes lo llaman como `./init.sh`.
   Hasta que hagas esto, `init.sh` falla a propósito.
4. Abre `claude` en la raíz del proyecto y pega tu primer ticket completo pidiéndole
   **"añade esto como feature nueva"**. El `leader` lo registra en `tasks.json` como
   `pending` y guarda el texto íntegro en `progress/<feature>-session-context.md`.
   `tasks.json` arranca vacío y no se edita a mano: lo mantiene el leader.
5. Haz commit de todo esto (`.claude/agents/` incluido) para que el equipo comparta los
   mismos agentes.
6. Pídele: **"implementa la siguiente tarea pendiente"**. `CLAUDE.md` hará que arranque
   como `leader`, lea `tasks.json`, coja la primera tarea que no esté `done` (el orden del
   array es la prioridad) y lance al `spec-author`.

## El flujo, tal como lo vas a vivir

1. **Pending → spec-author**: te escribe `requirements.md` (formato EARS, ver
   `specs/SPECS_FORMAT.md`), `design.md` y `tasks.md` dentro de `specs/<feature>/`. Para
   solo. Si al releer los requisitos encuentra preguntas que solo tú puedes contestar, para
   antes de `design.md` y la tarea queda en **`needs_clarification`** hasta que respondas.
2. **spec_ready → tú apruebas**: lees `requirements.md` y `design.md`, pides cambios si
   hace falta, y cuando estés de acuerdo le dices al leader que pase la tarea a
   `in_progress`. Este paso es obligatorio y no se puede saltar — así se evita que el
   agente se vaya 24h por libre sin que hayas visto qué va a construir.
3. **in_progress → implementer**: ejecuta `tasks.md` tarea a tarea, con el mínimo contexto
   posible (solo la carpeta `specs/<feature>/` y las `rules/`), corriendo `init.sh` y
   marcando cada tarea como hecha.
4. **in_review → reviewer**: valida trazabilidad (cada requisito EARS tiene un test que lo
   cita por id), que el diseño se respetó, que los tests tienen sentido (no solo que pasan)
   y que se siguieron las `rules/`. Mide el diff contra el `base_ref` que el leader anotó al
   arrancar la implementación, así que el alcance es objetivo. Aprueba o rechaza con
   feedback concreto.
5. **done**: el leader te muestra el resumen final y **espera tu confirmación**; solo
   entonces anexa el session-context completo a `history.md` y borra
   `progress/<feature>-session-context.md`.

## Cuándo saltarte SDD (`use_sdd: false`)

Para tareas muy pequeñas y sin ambigüedad (typos, un parámetro nuevo, un fix trivial),
márcalas como `"use_sdd": false` en `tasks.json`. El leader se saltará spec-author y
design.md, y mandará directo al implementer con una descripción de una línea. Úsalo con
criterio: en caso de duda, deja SDD completo.

## Alternativa: método simplificado (sin subagentes)

Si el proyecto es un MVP pequeño o vas solo, puedes no montar el harness completo y en su
lugar:

1. Conversar con Claude (chat o Claude Code) para construir un único `requirements.md` con
   stack, negocio, modelo de datos, APIs, UX/UI e integración de IA.
2. Pedirle a Claude Code que use **plan mode** (`Shift+Tab` para entrar en plan mode) para
   generar un `plan.md` con el desglose de tareas y dependencias a partir de ese
   `requirements.md`.
3. Salir de plan mode y ejecutar los prompts del `plan.md` uno a uno.
4. Revisión humana del resultado.

Puedes seguir usando `rules/` y `init.sh` de esta carpeta con este método simplificado sin
necesidad de `.claude/agents/` ni `tasks.json` — son piezas independientes.

## Cómo elegir

| | Método simplificado | Harness con subagentes (esta carpeta) |
|---|---|---|
| Ficheros a mantener | 1 (`requirements.md` + `plan.md` generado) | 4+ por feature, pero reutilizables |
| Esfuerzo inicial | Bajo | Medio (rellenar `rules/` e `init.sh` una vez) |
| Trazabilidad requisito→test | Manual | Automática vía notación EARS |
| Puntos de aprobación humana | 1 (al final) | 2+ (spec y, opcionalmente, review) |
| Encaja mejor con | MVPs, proyectos individuales | Equipos, proyectos de larga duración, specs que cambian a menudo |

## Personalización (esto es solo tu punto de partida)

- Cambia dónde se guarda el estado: en vez de `tasks.json` puedes decirle al `leader` que
  use un MCP de Linear/Jira.
- Cambia el trigger de commits: edítalo en `rules/global-conventions.md` y en
  `implementer.md`.
- Añade una rama nueva por feature: díselo al `leader.md` en la sección de protocolo.
- Añade más agentes especializados (ej. `security-reviewer`, `db-migrator`) copiando el
  patrón de `.claude/agents/*.md`.

La idea de fondo (de ambos vídeos): no copies un flujo ajeno tal cual — entiende el
patrón (especificar → aprobar → implementar → revisar, con contexto externo curado en vez
de memoria de chat) y móntate el arnés que encaje con cómo trabajas tú o tu equipo.
