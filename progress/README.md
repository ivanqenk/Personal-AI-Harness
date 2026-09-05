# progress/

Un fichero de **contexto de sesión** por ticket/feature, nombrado
`<id>-session-context.md` (ej. `F1-session-context.md`, o el id real del ticket si lo
tienes: `PROJ-1234-session-context.md`). Plantilla en `_template-session-context.md`.

Objetivo: si se corta la sesión de Claude Code o simplemente lo retomas otro día, el
siguiente agente (o tú mismo) lee este fichero primero y sabe exactamente dónde quedó todo
— ticket original, qué se hizo, por dónde retomar, decisiones sueltas — sin tener que
reconstruir el contexto desde el chat (que además no persiste entre sesiones).

El `leader` lo crea al registrar el ticket y lo actualiza al final de cada fase/sesión. El
`spec-author`, `implementer` y `reviewer` añaden ahí sus notas de avance en vez de dejarlas
solo en el chat.

Cuando una feature llega a `done`, su contenido se resume y se mueve a `history.md`, y este
fichero se puede borrar.
