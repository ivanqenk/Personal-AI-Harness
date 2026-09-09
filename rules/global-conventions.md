# Convenciones globales

> Rellena/edita este fichero para tu proyecto concreto. Es lo primero que leen el leader,
> el implementer y el reviewer.

## Git
- [ ] ¿Un commit por tarea completada de `tasks.md`? Sí/No — si sí, formato del mensaje:
      `<tipo>(<id-tarea>): <resumen>` ej. `feat(T4): registrar nuevo parser`
- [ ] ¿Rama nueva por cada feature/spec? Sí/No — convención de nombre: `feature/<slug>`
- [ ] ¿Se abre PR automáticamente al terminar la review? Sí/No

Marques lo que marques aquí, el reviewer no depende de ello para saber qué revisar: el leader
anota `base_ref` (el `git rev-parse HEAD` del momento en que la tarea pasó a `in_progress`) en
`tasks.json`, y la review se mide con `git diff <base_ref>...HEAD`. Así el alcance es el mismo
trabajes con rama por feature o directamente sobre la principal.

## Human-in-the-loop
- La aprobación de `requirements.md` + `design.md` (paso `spec_ready`) SIEMPRE requiere
  confirmación humana explícita. Ningún agente puede saltarse este paso.
- Cerrar una feature (`in_review` → `done`) también requiere confirmación humana: el leader
  muestra el resumen final y espera un "sí" antes de archivar en `history.md`. Si prefieres
  que cierre solo cuando el reviewer aprueba, cámbialo aquí y en `.claude/agents/leader.md`
  — pero cámbialo en los dos sitios, no dejes que se contradigan.

## Testing
- Framework de tests: <pytest / jest / phpunit / ...>
- Comando para correr toda la suite: <comando> (debe coincidir con lo que hace `init.sh`)
- Cobertura mínima esperada por feature: <opcional>
- **Trazabilidad RF→test (regla del arnés, no negociable)**: el nombre de cada test cita el
  id del requisito que cubre — `test_RF3_...` en Python, `it('RF-3: ...')` en JS/PHP, lo
  equivalente en tu framework. `init.sh` comprueba que cada `RF-x` de cada
  `specs/*/requirements.md` aparece citado en `RUTAS_TESTS`; sin esa convención el check no
  puede correr y la trazabilidad vuelve a ser una opinión.

## Estilo de código
- Formateador/linter: <prettier, black, pint, ...> y comando para ejecutarlo
- Patrones prohibidos explícitamente: <ej. "no usar `any` en TypeScript", "no lógica de
  negocio en controladores">

## Dónde vive el contexto
- Notas de trabajo en curso de cada agente: `progress/<feature>-session-context.md` (no solo en el chat).
- Histórico de features completadas: `history.md`.
