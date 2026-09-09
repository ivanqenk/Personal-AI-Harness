# Requirements — <nombre-feature>

## Contexto
<1-2 frases: qué problema resuelve esta feature y para quién>

## Usuarios
<quién usa esto y en qué situación>

## Historias de usuario
- Como <rol>, quiero <acción>, para <beneficio>.

## Requisitos funcionales (notación EARS, RF-x)

> Cada id es el que citará el test que lo cubre (`test_RF1_...`, `it('RF-1: ...')`), y eso
> lo comprueba `init.sh`. No renumeres un RF ya implementado.

- **RF-1**: Cuando <evento>, el sistema debe <respuesta>.
- **RF-2**: Si <condición de error>, entonces el sistema debe <manejo del error>.

## Casos límite
- <qué pasa con entradas vacías, valores extremos, concurrencia, permisos, etc.>

## Fuera de alcance
- <qué NO se va a construir en esta feature>

## Criterios de finalización
- <cómo se sabe, de forma objetiva, que esta feature está terminada>

## Preguntas abiertas
- <dudas que el humano debe resolver antes de aprobar la spec — borrar sección si no hay>

---
> **Clarificación**: antes de pasar a `design.md`, relee este documento una vez completo
> como si fueras QA. Marca cualquier requisito ambiguo, contradictorio o incompleto en
> "Preguntas abiertas" — no lo arrastres al diseño.
