# Prompts por fase

Chuleta con el prompt esencial de cada fase del flujo. Escribe estos prompts a Claude Code
en la raíz del repo (donde está `CLAUDE.md`).

| Fase | Prompt |
|---|---|
| Arrancar / continuar (la siguiente pendiente) | `Implementa la siguiente tarea pendiente.` |
| Retomar una feature específica | `Retoma <id/feature>.` — el leader cruza tasks.json con su session-context para saber exactamente por dónde va. |
| Añadir un ticket nuevo (sin arrancarlo) | Pega el ticket completo (descripción, criterios de aceptación, lo que tengas) y añade: `Añade esto como feature nueva.` Queda en pending. No hace falta que lo resumas tú ni que toques tasks.json — el leader lo registra y guarda el ticket completo. |
| Añadir un ticket nuevo y arrancarlo ya | Igual que arriba, pero añade: `...y arráncala ya.` |
| Ver estado | `¿Cuál es el estado actual de tasks.json? Resume cada feature y su fase.` |
| Ver instincts pendientes de promoción | `¿Hay alguna entrada en instincts.md con 3+ apariciones lista para pasar a rules/?` |
| Aprobar spec | `Apruebo la spec de <feature>. Pásala a in_progress.` |
| Pedir cambios en la spec | `La spec de <feature> no está bien: <qué cambiar>. Actualiza requirements.md/design.md y vuelve a pedirme aprobación.` |
| Saltar SDD en una tarea trivial | `Marca <feature> con use_sdd: false e impleméntala directamente: <descripción corta>.` |
| Forzar revisión | `Lanza al reviewer sobre <feature> aunque el implementer no lo haya pedido todavía.` |
| Rechazar en review | `El reviewer tiene razón / no la tiene en <punto concreto>. <qué hacer>.` |
| Cambiar una feature ya terminada | `Necesito cambiar el comportamiento de <feature> ya hecha: <qué cambia>. Empieza editando su spec, no el código.` |
| Cerrar y archivar | `Marca <feature> como done.` — el leader te muestra primero un resumen final con código y explicación, y luego archiva en history.md. |

## Notas

- No hace falta que nombres al agente explícitamente ("lanza al spec-author..."): el
  `leader` decide a quién delegar según el estado en `tasks.json`. Nómbralo solo cuando
  quieras forzar algo fuera del flujo normal (ej. "forzar revisión").
- Si usas otra CLI (Codex, Cursor, opencode...) en vez de Claude Code, estos mismos prompts
  valen igual porque el contexto vive en `AGENTS.md`, no en algo específico de Claude Code.
