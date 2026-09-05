# progress/

Un fichero de **contexto de sesión** por ticket/feature, nombrado
`<feature>-session-context.md`, donde `<feature>` es el slug del campo `feature` de
`tasks.json` (ej. `login-social-session-context.md`). Plantilla en
`_template-session-context.md`.

Objetivo: si se corta la sesión de Claude Code o simplemente lo retomas otro día, el
siguiente agente (o tú mismo) lee este fichero primero y sabe exactamente dónde quedó todo
— ticket original, qué se hizo, por dónde retomar, decisiones sueltas — sin tener que
reconstruir el contexto desde el chat (que además no persiste entre sesiones).

El `leader` lo crea al registrar el ticket y lo actualiza al final de cada fase/sesión. El
`spec-author`, `implementer` y `reviewer` añaden ahí sus notas de avance en vez de dejarlas
solo en el chat.

Cuando una feature llega a `done`, su contenido se resume y se mueve a `history.md`, y este
fichero se puede borrar.
