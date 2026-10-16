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
  tarea a `in_progress`, y con `--rapido` al cerrar una tarea de nivel `rapido`. Falla a propósito mientras no esté personalizado para el
  proyecto: un gate que aprueba sin ejecutar nada es peor que no tener gate.
- `.claude/settings.json` + `.claude/hooks/` — el gate automático que hace insaltable la regla de
  oro (ver abajo).

## Regla de oro

Nunca implementes código de una feature nueva si no existe ya `specs/<feature>/tasks.md`
**aprobado por el humano**, es decir con la tarea en `in_progress` o posterior en
`tasks.json`. `spec_ready` significa que la spec está escrita pero **todavía no aprobada**:
no basta. Si no existe spec, lanza primero al `spec-author`.

Excepción: las tareas de nivel `rapido` o `ligero` (ver "Niveles de proceso" abajo), que no
llevan spec porque no la necesitan.

Esta regla no depende de que ningún agente se acuerde de ella: un hook `PreToolUse` bloquea
toda escritura sobre código de producción mientras no haya una tarea `in_progress` en
`tasks.json`. Los ficheros del arnés (`specs/`, `progress/`, `docs/`, `rules/`, `tasks.json`...)
se escriben siempre, porque son justo lo que hay que poder editar *antes* de tener una spec.
Si el hook bloquea algo, el arreglo es mover la tarea al estado que toca — nunca desactivar el
gate ni escribir el fichero por otra vía.

## Niveles de proceso

No todo cambio merece las seis fases. Pasar un cambio de color por spec, implementer y
reviewer cuesta decenas de miles de tokens para proteger contra un riesgo que no existe. Cada
tarea lleva un campo `"nivel"` en `tasks.json`, y lo decide el leader al registrarla:

| Nivel | Cuándo | Qué recorre |
|---|---|---|
| `rapido` | Cambio **sin lógica**: estilos, colores, textos, copys, typos, espaciados, iconos, un valor de config o una constante que no cambia comportamiento. 1-2 ficheros. | El leader lo hace él mismo, sin subagentes. Verifica con `./init.sh --rapido`. Una línea en `history.md`. |
| `ligero` | Lógica **acotada y sin ambigüedad**: un parámetro nuevo, un bug con causa clara y arreglo localizado. Se puede describir en 1-3 frases sin decisiones de diseño. | Sin spec. `implementer` contra la descripción, `reviewer` en modo reducido, resumen corto al cerrar. |
| `completo` | Todo lo demás: funcionalidad nueva, cambios de comportamiento, varias capas, cualquier cosa con decisiones de diseño o dudas. | El flujo SDD entero. |

**Nunca son `rapido` ni `ligero`**, por pequeño que sea el cambio: autenticación, permisos,
dinero/pagos, datos personales, migraciones o esquema de BD, IaC y despliegue, contratos de
API pública, y cualquier cosa que contradiga o roce `docs/constitution.md`. Ahí el tamaño
del diff no dice nada del riesgo.

**Escalado**: si al trabajar una tarea `rapido` aparece lógica, o una `ligero` necesita una
decisión de diseño, se para y se sube de nivel avisando al humano. Escalar es barato;
equivocarse a la baja no. Por eso el leader puede clasificar con generosidad, pero nunca
bajar el nivel de una tarea ya empezada sin que el humano lo pida.

El humano siempre puede forzar el nivel ("hazlo rápido", "pásalo por SDD completo"), salvo
la lista de arriba, que no baja de `ligero` aunque lo pida — en ese caso el leader le avisa
del motivo y le deja decidir entre `ligero` o `completo`.

Las tareas antiguas con `"use_sdd": false` y sin `nivel` se tratan como `ligero`.

## Verificación y tokens

Cada línea que un comando escribe en el chat la paga el modelo. `init.sh` está hecho para
eso: si un paso pasa, imprime una línea; si falla, solo la cola de la salida. No lo
sustituyas por llamadas sueltas a la suite con salida completa, y no lo ejecutes dos veces
seguidas sin haber cambiado nada entre medias.

Si la suite es lenta o necesita un entorno que la IA no tiene (BD real, emuladores,
dispositivos), el humano puede correrla a mano y pegar solo el resumen de fallos: vale como
verificación si lo indica explícitamente.

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
→ `spec_ready` → `in_progress` → `in_review` → `done`. En nivel `completo` ninguno es
opcional: el `status` por sí solo debe bastar para saber en qué fase estás si la sesión se
corta. `ligero` entra directo en `in_progress`; `rapido` también, y al terminar sale de
`tasks.json` sin pasar por `in_review`. El detalle de cada transición está en
`.claude/agents/leader.md`.

## Principio de cambio (spec-first)

Si una feature ya está `done` y hay que cambiar su comportamiento, el cambio empieza
**siempre** editando `specs/<feature>/requirements.md` (y `design.md` si aplica), nunca
tocando el código directamente. Trátalo como una spec nueva que vuelve a `pending` con una
nota indicando qué requisito cambia y por qué.
