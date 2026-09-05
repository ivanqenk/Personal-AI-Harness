# Guía de uso: instalación y día a día

## 1. Cómo implementarlo en un proyecto nuevo

1. **Crea el proyecto vacío** — inicializa el repo como siempre (`git init`, tu framework,
   etc.). El arnés no depende de que exista código todavía: funciona igual de bien en un
   repo vacío que en uno con historia.
2. **Coloca el arnés según si es solo para ti o para equipo:**
   - **Solo para ti (tu caso)**: copia `.claude/agents/*.md` a `~/.claude/agents/` (fuera
     del repo, disponible en cualquier proyecto). El resto (`CLAUDE.md`, `AGENTS.md`,
     `docs/`, `specs/`, `rules/`, `tasks.json`, `instincts.md`, `prompts.md`, `init.sh`,
     `progress/`, `history.md`) sí vive dentro del repo, pero añádelo a `.gitignore` para
     que no se suba en los commits.
   - **Para equipo**: copia toda la carpeta a la raíz tal cual y haz commit de todo,
     incluido `.claude/agents/`, para que todos usen los mismos subagentes.
3. **Rellena `docs/constitution.md`** — 4-6 principios innegociables reales del proyecto
   (seguridad, compatibilidad, dependencias, estilo). Si no sabes qué poner todavía, déjalo
   con 2-3 básicos y amplíalo según avances; no hace falta perfección desde el día 1.
4. **Rellena `rules/*.md` con tu stack real** — `global-conventions.md` (git, testing, si
   la aprobación humana también aplica en la review), `backend-instructions.md` y
   `frontend-instructions.md` con el framework, estructura de carpetas y patrones
   prohibidos reales. Esto es lo que evita que la IA invente convenciones. En stacks poco
   estándar (COBOL, ABAP) dedícale más tiempo a esto: cuanto menos "sentido común" propio
   tenga el modelo del stack, más detallado tiene que ser este fichero.
5. **Rellena `init.sh`** — comandos reales: instalar dependencias, linter, tests. Lo va a
   ejecutar cada agente antes de darse por terminado, así que tiene que reflejar de verdad
   cómo se verifica el proyecto. Si el código no vive en un filesystem accesible por bash
   (mainframe, transportes SAP), `init.sh` tiene que ser un wrapper a lo que sí tengas
   accesible. Comprueba que conserva el bit de ejecución (`chmod +x init.sh`): los agentes
   lo invocan como `./init.sh` y, si no lo es, el `leader` se para en su primera
   precondición.
6. **Prueba con tu primer ticket real** — no edites `tasks.json` a mano; ábrelo con
   `claude` y pega el ticket completo (descripción, criterios de aceptación, lo que tengas)
   pidiéndole *"añade esto como feature nueva"* (sin arrancarlo todavía). El `leader`
   registra la entrada en `tasks.json` como `pending` y guarda el ticket completo en
   `progress/<feature>-session-context.md` para que el `spec-author` lo use tal cual, sin
   depender de que tú lo resumas bien. `tasks.json` viene vacío a propósito: la primera
   entrada la crea el leader con tu ticket. Empieza con algo pequeño para probar el flujo
   de punta a punta antes de meter un ticket grande.
7. **Haz commit** — de lo que corresponda según el punto 2 (con `.gitignore` si es uso
   personal, o de todo si es para equipo).
8. **Abre Claude Code en la raíz y arranca** — ejecuta `claude` desde la raíz del proyecto.
   `CLAUDE.md` (que apunta a `AGENTS.md`) se carga solo, y si pusiste los agentes en
   `~/.claude/agents/`, Claude Code los encuentra igual sin que estén en el repo. Tu primer
   prompt real del día a día es *"implementa la siguiente tarea pendiente"* — ahí es donde
   el ticket que añadiste en el paso 6 arranca de verdad.

## 2. Cómo se usa en el día a día

Cada vez que abres Claude Code, entras por uno de dos caminos según de dónde partas. A
partir de ahí, el resto del ciclo es el mismo para los dos.

### Flujo A — Ticket nuevo

1. Pega el ticket completo en el chat (descripción, criterios de aceptación, lo que
   tengas) y pide una de las dos:
   - *"Añade esto como feature nueva."* → queda en `pending`, para arrancarla otro día
     (entonces la retomas por el Flujo B).
   - *"Añade esto como feature nueva y arráncala ya."* → el `leader` la registra y lanza
     directo al `spec-author`. Sigue en el paso 2 de "Lo que viene después", abajo.
2. En cualquiera de los dos casos, el `leader` registra la entrada en `tasks.json` y guarda
   el ticket completo (tal cual, sin que tú lo resumas) en
   `progress/<feature>-session-context.md`. Nunca tocas el JSON a mano.
3. Si es algo trivial y sin ambigüedad, pide directamente `use_sdd: false` y sigue sin
   pasar por spec completa.

### Flujo B — Continuar algo ya en curso

1. Pide una de las dos:
   - *"Implementa la siguiente tarea pendiente."* → el `leader` toma la primera tarea que
     no esté `done` en el orden del array de `tasks.json`. No hay campo de prioridad: si
     quieres adelantar algo, muévelo arriba o pídelo por nombre.
   - *"Retoma \<id/feature\>."* → si quieres una en concreto, no la siguiente en la lista.
2. El `leader` lee `tasks.json` y cruza eso con el checklist "Progreso" del
   `session-context` de esa tarea (si ya existe) para confirmar de verdad por dónde se
   quedó, sea cual sea la fase — esperando aprobación de spec, implementación a medias,
   pendiente de review, etc. — y continúa desde ahí, sin que tengas que explicarle el
   contexto tú.

### Lo que viene después (igual en ambos flujos)

2. **Revisa y aprueba la spec** — cuando la tarea pase a `spec_ready`, lee
   `requirements.md` y `design.md` (el leader te los resume). Si algo no cuadra, pide
   cambios concretos. Si está bien: *"Apruebo la spec de \<feature\>, pásala a
   in_progress."* Este paso nunca se salta.
3. **Deja trabajar al implementer, pero lee los tests** — va marcando tareas de
   `tasks.md` una a una y corriendo `init.sh`. No hace falta mirar cada línea de código,
   pero sí conviene leer los tests que va generando: ahí es donde se detectan
   malentendidos pronto.
4. **Deja que el reviewer valide** — al terminar todas las tareas, el leader lanza
   automáticamente al `reviewer`. Comprueba trazabilidad RF→test, diseño y convenciones, y
   también anota en `instincts.md` si detecta una corrección o preferencia tuya que ya se
   repitió antes y no está en `rules/`. Si rechaza, vuelve a `in_progress` con notas
   concretas; si aprueba, queda lista para cerrar.
5. **Cierra y archiva** — *"Marca \<feature\> como done."* Antes de archivar, el leader te
   muestra en pantalla un resumen completo: qué se pidió, qué se construyó, el código
   relevante, las decisiones clave, cómo se verificó, y si hay alguna entrada de
   `instincts.md` lista para promoverse a `rules/` (3+ apariciones). Solo después mueve
   todo a `history.md` y borra el `session-context`.
6. Vuelve al Flujo A o al Flujo B según toque, y se repite.

## 3. Notas prácticas

- **Chuleta de prompts**: `prompts.md` tiene el prompt exacto para cada situación
  (aprobar, rechazar, cambiar una feature ya hecha, etc.) — úsalo como referencia rápida en
  vez de memorizar la sintaxis.
- **Sesión cortada**: si a mitad de una tarea se corta la sesión de Claude Code, no
  pierdes contexto. Al volver a abrir y pedir "continúa", el `leader` relee `tasks.json` +
  `progress/<feature>-session-context.md` y retoma donde quedó, sin depender del historial
  del chat. Si quieres ver tú mismo en qué fase está algo sin pedírselo a Claude, abre el
  `session-context` de ese ticket y mira el checklist "Progreso" — las casillas marcadas
  te dicen exactamente hasta dónde llegó.
- **No acumules trabajo en curso**: en features grandes, conviene mantener `tasks.json`
  con solo 1-2 features `in_progress` a la vez, para que la revisión humana no se acumule
  y `history.md` quede como un log legible de decisiones, no un volcado.
- **Costo por rol**: `spec-author` corre en opus a propósito (una spec mal pensada
  contamina todo lo demás), `leader`/`implementer`/`reviewer` en sonnet. Si una feature
  toca seguridad, dinero o una decisión difícil de revertir, invoca `/model opus`
  manualmente antes de pedir la review — no lo hace por defecto.
- **`instincts.md`**: el `reviewer` va anotando ahí correcciones que se repiten pero que
  todavía no están en `rules/`. Cuando el `leader` te avise de que una entrada acumuló 3+
  apariciones, revísala y decide si la promueves a `rules/` — es un paso manual, no
  automático.
