---
description: Arranca la especificación de una funcionalidad mobile (SPEC → PLAN → TASKS) aplicando las guías IMALE
argument-hint: "[descripción de la funcionalidad]"
---
Quiero que me ayudes a escribir la especificación de una funcionalidad para esta app: $ARGUMENTS

Primero, revisa el proyecto para entender cómo funciona y qué convenciones sigue. Revisa también:

- `~/.pi/agent/MOBILE_GUIDELINES.md` — puntos que debe cubrir el SPEC en una app mobile
- `~/.pi/agent/GENERIC_RULES.md` — reglas de trabajo (alcance, datos, validación, documentación)
- `~/.pi/agent/templates/SPEC_TEMPLATE.md` — plantilla que debes completar
- las skills `flutter-guidelines` y `dart-guidelines` si el proyecto es Flutter/Dart

Incorpora al proceso las revisiones de esas guías que sean pertinentes para esta funcionalidad.

Después, prepara un borrador de la especificación con la información que podamos comprobar, para completarlo y corregirlo juntos. La especificación debe definir:

- Objetivo y comportamiento esperado.
- Qué está incluido y qué queda fuera del alcance.
- Flujos, reglas de negocio y casos de error.
- Criterios de aceptación concretos y cómo validar cada uno.
- Restricciones técnicas y decisiones pendientes.

Reglas del proceso:

- No asumas decisiones que no estén definidas: pregúntame antes de incorporarlas. Puedes proponer opciones y recomendar una, pero espera mi confirmación antes de reflejarla como decisión tomada.
- Investiga todo lo que puedas comprobar en el código. Lo que no esté resuelto o no pueda deducirse con certeza queda marcado como PENDIENTE.
- Hazme pocas preguntas por vez y actualiza la especificación con mis respuestas.
- No implementes nada hasta que revisemos y aprobemos explícitamente la especificación.
- No incluyas diseño de clases, tablas, componentes, archivos ni algoritmos: eso pertenece al PLAN.

Presta especial atención, cuando apliquen, a:

- El comportamiento sin conexión.
- La persistencia local y su relación con la fuente remota.
- La convivencia entre datos obtenidos de forma remota y datos creados por el usuario.
- La sincronización y actualización de los datos remotos.
- Los estados de interfaz: carga, contenido, vacío, error y éxito.
- Recreación de pantalla, segundo plano y reapertura de la app.

Al terminar el borrador, indícame qué secciones quedan pendientes y qué decisiones necesitas confirmar antes de pasar al PLAN.
