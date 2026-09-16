---
name: flutter-guidelines
description: Expert in Flutter application standards. Use when building or reviewing Flutter apps (architecture, widgets, state/lifecycle, navigation, networking, persistence, connectivity, accessibility, performance, i18n, permissions, background work).
metadata:
  author: IMALE.org
  version: "1.0"
---
# Flutter Guidelines

Estas directrices complementan [`MOBILE_GUIDELINES.md`](../MOBILE_GUIDELINES.md) y la skill `dart-guidelines`, y definen criterios específicos para proyectos Flutter. Aplicar solo los puntos que correspondan a la funcionalidad; si falta definir un comportamiento, consultarlo antes de asumirlo.

## 1. Arquitectura y estructura

- Organizar el código por **features** y mantener las responsabilidades separadas.
- Seguir **Clean Architecture** cuando el proyecto la adopte: presentación, dominio y datos claramente diferenciados.
- Usar **Cubit/BLoC** para la gestión del estado cuando sea el estándar del proyecto.
- Mantener una única responsabilidad por widget, Cubit/BLoC, caso de uso y repositorio.
- Evitar lógica de negocio dentro de widgets.
- Mantener las dependencias orientadas hacia capas internas y evitar acoplamientos innecesarios.
- Centralizar la inyección de dependencias, por ejemplo mediante `get_it`, cuando forme parte del proyecto.
- Mantener la configuración por entorno separada del código de aplicación.

## 2. Widgets y UI

- Preferir widgets pequeños, componibles y reutilizables.
- Evitar widgets excesivamente grandes con demasiadas responsabilidades.
- No duplicar estructuras de UI que puedan convertirse en componentes reutilizables.
- Mantener separados presentación, lógica de estado y acceso a datos.
- Usar Material 3 o el sistema visual definido por el proyecto.
- Centralizar tema, tipografías, colores, espaciados y componentes comunes.
- Evitar valores mágicos repetidos en múltiples pantallas.

## 3. Estado y ciclo de vida

- Definir explícitamente qué estado es temporal y qué estado debe persistir.
- Considerar recreación de widgets, navegación, background/foreground y finalización del proceso.
- Evitar conservar listeners, streams, controllers o subscriptions después de su ciclo de vida.
- Liberar correctamente `AnimationController`, `TextEditingController`, `ScrollController`, streams y recursos similares.
- Evitar crear Cubits/BLoCs innecesariamente dentro de `build`.
- Impedir operaciones duplicadas producidas por pulsaciones repetidas.

## 4. Navegación

- Centralizar la estrategia de navegación.
- Definir qué ocurre al volver atrás, cancelar, abandonar formularios y regresar desde otra aplicación.
- Gestionar correctamente deep links, enlaces externos y notificaciones cuando formen parte del flujo.
- Evitar navegación implícita desde capas de dominio o datos.

## 5. Red y datos

- Mantener las llamadas de red fuera de la UI.
- Centralizar clientes HTTP, interceptores, autenticación y tratamiento de errores.
- Cuando se use Dio, mantener su configuración e interceptores en una capa dedicada.
- Modelar estados de carga, contenido, vacío, error y éxito.
- Definir el comportamiento ante timeout, desconexión, respuestas inválidas y reintentos.
- Evitar repetir peticiones idénticas sin una razón funcional.
- Si existe persistencia local, definir su relación con la fuente remota y el comportamiento ante conflictos.

## 6. Persistencia

- Definir qué datos se almacenan localmente y durante cuánto tiempo.
- Gestionar migraciones y compatibilidad con versiones anteriores.
- No almacenar información sensible sin una necesidad justificada y una protección adecuada.
- Evitar incluir secretos, tokens o credenciales en el código fuente o logs.

## 7. Conectividad y errores

- La aplicación debe contemplar ausencia de conexión y recuperación de conectividad.
- Diferenciar primer uso, datos previamente almacenados y datos obsoletos.
- Mostrar errores comprensibles para el usuario y conservar detalles técnicos fuera de la UI cuando corresponda.
- Permitir recuperación cuando la operación pueda repetirse de forma segura.

## 8. Adaptación y accesibilidad

- Diseñar para diferentes tamaños de pantalla y densidades.
- Evitar tamaños rígidos que provoquen overflow o contenido cortado.
- Contemplar cambios en el tamaño del texto del sistema.
- Respetar áreas seguras y elementos del sistema.
- Usar Semantics y etiquetas accesibles cuando sea necesario.
- Mantener un orden de foco lógico.
- No comunicar información únicamente mediante color, animación o gesto.

## 9. Rendimiento

- Evitar trabajo pesado dentro de `build`.
- Usar listas eficientes y construir únicamente los elementos necesarios.
- Optimizar imágenes y recursos.
- Evitar rebuilds innecesarios.
- Mover procesamiento costoso fuera del hilo principal cuando corresponda.
- Vigilar memoria, batería y consumo de datos.
- Mantener las operaciones de red, almacenamiento y procesamiento sin bloquear la interfaz.

## 10. Internacionalización

- No introducir textos visibles directamente en el código cuando el proyecto utilice i18n.
- Contemplar ES/EN u otros idiomas definidos por el proyecto.
- Considerar longitud variable de textos, pluralización, fechas, números, unidades y zonas horarias.
- No asumir formatos regionales fijos.

## 11. Permisos y capacidades nativas

- Solicitar únicamente los permisos necesarios.
- Gestionar permisos denegados, revocados o restringidos.
- Definir el comportamiento cuando una capacidad del dispositivo no esté disponible.
- Mantener aislada la integración con APIs nativas cuando sea posible.

## 12. Background y operaciones asíncronas

- No asumir que una tarea móvil puede continuar indefinidamente en segundo plano.
- Diseñar operaciones para poder interrumpirse y reanudarse.
- Evitar efectos duplicados al reintentar una operación.
- Gestionar correctamente cancelación y estados obsoletos.

## 13. Testing y validación

- Unit tests para lógica de dominio y casos de uso.
- Tests de Cubit/BLoC para transiciones de estado.
- Widget tests para comportamientos relevantes de UI.
- Integration tests para flujos críticos.
- Validar escenarios de conectividad, permisos, background/foreground, reapertura y diferentes tamaños de pantalla.
- Complementar los tests automatizados con validación en dispositivo, emulador o simulador.

## 14. Dependencias y mantenimiento

- Añadir una dependencia solo cuando aporte valor claro.
- Revisar compatibilidad con la versión de Flutter/Dart del proyecto.
- Evitar paquetes abandonados o innecesarios.
- Mantener versiones y configuración coherentes entre entornos.
- Antes de introducir una nueva librería, comprobar si la funcionalidad puede resolverse con APIs existentes o componentes ya presentes.

## 15. Criterio general

Toda implementación Flutter debe priorizar:

1. Claridad.
2. Separación de responsabilidades.
3. Testabilidad.
4. Accesibilidad.
5. Rendimiento.
6. Mantenibilidad.
7. Comportamiento correcto ante las condiciones reales de un dispositivo móvil.

Estas directrices no amplían automáticamente el alcance funcional. Los requisitos, decisiones técnicas y criterios de aceptación deben derivarse de la funcionalidad solicitada y de las decisiones confirmadas.
