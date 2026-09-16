<!--
/welcome — Muestra los comandos y flujos disponibles en IMALEagent
-->
# IMALEagent — Comandos rápidos

Para arrancar IMALEagent desde la terminal:

```bash
IMALEagent
# o también: pi
```

Una vez dentro, usa estos comandos:

## Subagentes y chains

Delega trabajo a especialistas:

```
/run-chain generic-implement-safe -- describe tu tarea aquí
/run-chain generic-fix-bug -- describe el bug aquí
/run-chain generic-discovery -- explora esta parte del código
/run-chain generic-research-and-plan -- investiga y planifica
```

## Agentes individuales

```
/run generic-reviewer "Revisa este código con foco en regresiones"
/run generic-parallel-review "Revisa este cambio (seguridad + tests + simplicidad)"
/run generic-doc-writer "Escribe un README para este módulo"
```

## Sesiones

```
/session      - información de la sesión actual
/resume       - explorar sesiones anteriores
/tree         - navegar ramas de la sesión
/export       - exportar sesión a HTML
/name <texto> - poner nombre a la sesión actual
```

## Diagnóstico

```
/router-status   - estado del routing y capacidades
/mcp             - herramientas de contexto pesado
```

## Especificaciones

```
/spec-mobile <funcionalidad>  - arrancar SPEC → PLAN → TASKS de una funcionalidad mobile
```

## Atajos

```
/settings             - configuración del agente
/model                - cambiar modelo
/theme                - cambiar tema
/welcome              - mostrar esta ayuda
```

## Skills activas

Se cargan automáticamente según la tarea. No necesitas invocarlas manualmente.
