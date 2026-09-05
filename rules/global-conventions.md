# Convenciones globales

> Rellena/edita este fichero para tu proyecto concreto. Es lo primero que leen el leader,
> el implementer y el reviewer.

## Git
- [ ] ¿Un commit por tarea completada de `tasks.md`? Sí/No — si sí, formato del mensaje:
      `<tipo>(<id-tarea>): <resumen>` ej. `feat(T4): registrar nuevo parser`
- [ ] ¿Rama nueva por cada feature/spec? Sí/No — convención de nombre: `feature/<slug>`
- [ ] ¿Se abre PR automáticamente al terminar la review? Sí/No

## Human-in-the-loop
- La aprobación de `requirements.md` + `design.md` (paso `spec_ready`) SIEMPRE requiere
  confirmación humana explícita. Ningún agente puede saltarse este paso.
- (Opcional) ¿También se requiere aprobación humana antes de pasar de `in_review` a `done`?

## Testing
- Framework de tests: <pytest / jest / phpunit / ...>
- Comando para correr toda la suite: <comando> (debe coincidir con lo que hace `init.sh`)
- Cobertura mínima esperada por feature: <opcional>

## Estilo de código
- Formateador/linter: <prettier, black, pint, ...> y comando para ejecutarlo
- Patrones prohibidos explícitamente: <ej. "no usar `any` en TypeScript", "no lógica de
  negocio en controladores">

## Dónde vive el contexto
- Notas de trabajo en curso de cada agente: `progress/<feature>-session-context.md` (no solo en el chat).
- Histórico de features completadas: `history.md`.
