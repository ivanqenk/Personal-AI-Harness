# Instincts

Correcciones o preferencias que se repiten entre tareas pero que todavía no son una regla
formal en `rules/`. El `reviewer` alimenta este fichero al cerrar cada tarea; tú decides
cuándo promover una entrada a regla real.

## Cómo se alimenta

Al final de cada tarea, el `reviewer` se pregunta explícitamente: *"¿hubo alguna corrección
o preferencia del humano en esta tarea que se repita respecto a tareas anteriores y que no
esté ya en `rules/global-conventions.md`, `rules/backend-instructions.md` o
`rules/frontend-instructions.md`?"* Si la hay, añade o actualiza una entrada aquí.

## Formato de cada entrada

```
## [confianza: baja] <regla observada, en una frase imperativa>
- Observado en: <id-tarea-1>, <id-tarea-2>
- Contexto: <qué pasó — qué corrigió el humano, o qué patrón se repitió>
```

La confianza sube de `baja` a `media` a `alta` según se acumulan apariciones en
`Observado en`.

## Cuándo promover a `rules/`

Cuando una misma entrada acumule **3 o más** tareas distintas en "Observado en", el
`leader` te avisa en el resumen final de que hay una regla candidata a promoción. Tú
decides: si la promueves, muévela (reescrita como regla obligatoria, no como observación)
a `rules/global-conventions.md`, `rules/backend-instructions.md` o
`rules/frontend-instructions.md` según corresponda, y bórrala de aquí.

Este ciclo es deliberadamente manual — sin scoring automático ni motor de confianza — es
lo justo para un arnés de una sola persona. No lo compliques con más infraestructura.

---

<!-- Vacío al empezar. El reviewer añade entradas aquí a medida que detecta patrones. -->
