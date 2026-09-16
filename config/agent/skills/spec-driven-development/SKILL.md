---
name: spec-driven-development
description: Expert in designing and validating specifications before coding. Use when starting a new feature or complex change to define goals, structure, and tests.
metadata:
  author: IMALE.org
  version: "1.0"
---
# Skill de Spec-Driven Development (SDD)

## Descripción General
Experto en diseñar y validar especificaciones antes de escribir una sola línea de código. Sigue el flujo "Gated Workflow" para asegurar alineación total con los requisitos.

## Gotchas (Reglas Críticas)
- **Saltarse Pasos**: Prohibido implementar sin tener la especificación (`Specify`) y las tareas (`Tasks`) aprobadas.
- **Vaguedad**: Si un objetivo no es medible o verificable, la especificación es inválida.
- **Falta de Límites**: Si no defines qué está "fuera de alcance", el proyecto sufrirá de *scope creep*.

## Flujo de Trabajo (Gated Workflow)
- [ ] **Paso 1: Especificar (Specify)**
  - Partir de la plantilla `templates/SPEC_TEMPLATE.md` (~/.pi/agent/templates/) y guardar el resultado como `SPEC.md` en la carpeta de la funcionalidad.
  - Definir: Objetivo, Comandos, Estructura, Estilo, Testing y Límites.
  - Si es una app mobile, cubrir los puntos de `MOBILE_GUIDELINES.md` (~/.pi/agent/MOBILE_GUIDELINES.md).
  - Obtener aprobación explícita del usuario.
- [ ] **Paso 2: Planificar (Plan)**
  - Partir de `templates/PLAN_TEMPLATE.md` y guardar el resultado como `PLAN.md` junto al SPEC.
  - Diseñar la solución técnica detallada basada en la especificación aprobada.
- [ ] **Paso 3: Tareas (Tasks)**
  - Crear un archivo `task.md` con el desglose atómico de pasos, referenciando RF/CA.
- [ ] **Paso 4: Implementar (Implement)**
  - Seguir estrictamente el orden de las tareas.
  - Mantener `task.md` actualizado con el progreso (`[/]`, `[x]`).
- [ ] **Aplicar en paralelo las reglas de trabajo de `GENERIC_RULES.md`** (alcance, datos, validación, documentación).

## Atajos
- Proyecto Flutter/Dart: cargar también las skills `flutter-guidelines` y `dart-guidelines`.
- Prompt de arranque de una spec mobile: `/spec-mobile`.

## Criterios de Éxito
- Cero retrabajo por malentendidos de requisitos.
- Seguimiento visual del progreso mediante `task.md`.
- Código final que coincide 1:1 con la especificación original.
