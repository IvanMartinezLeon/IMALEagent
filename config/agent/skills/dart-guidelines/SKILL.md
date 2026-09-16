---
name: dart-guidelines
description: Expert in Dart code quality for Flutter projects. Use when writing, reviewing or refactoring Dart code (null safety, types, async, error handling, immutability, testing, module boundaries).
metadata:
  author: IMALE.org
  version: "1.0"
---
# Dart Guidelines

Estas directrices definen criterios específicos para código Dart en proyectos Flutter. Complementan [`MOBILE_GUIDELINES.md`](../MOBILE_GUIDELINES.md) y la skill `flutter-guidelines`.

## 1. Estilo general

- Escribir código claro, explícito y fácil de mantener.
- Seguir las convenciones oficiales de Dart y mantener `dart format` aplicado.
- Usar nombres descriptivos y consistentes.
- Evitar abreviaturas que reduzcan la legibilidad.
- Mantener funciones y clases pequeñas cuando sea razonable.
- Evitar comentarios que simplemente repitan lo que ya expresa el código.

## 2. Null safety

- Mantener null safety activado.
- No usar `!` como mecanismo habitual para evitar errores de análisis.
- Preferir comprobaciones explícitas y estructuras que hagan evidente por qué un valor no puede ser `null`.
- Evitar convertir un valor nullable a non-nullable sin una garantía real.

## 3. Tipos y API

- Declarar tipos explícitos cuando mejoren la comprensión del código.
- Aprovechar la inferencia de tipos cuando el tipo resulte evidente.
- Evitar `dynamic` salvo que exista una razón técnica concreta.
- Mantener APIs públicas pequeñas y coherentes.
- Evitar exponer implementaciones concretas cuando una abstracción sea suficiente.

## 4. Clases y responsabilidades

- Una clase debe tener una responsabilidad claramente identificable.
- Evitar clases que mezclen UI, negocio, persistencia y comunicación de red.
- Usar composición antes que herencia cuando simplifique el diseño.
- Mantener modelos, entidades, casos de uso, repositorios y servicios separados cuando la arquitectura del proyecto lo requiera.
- Preferir objetos inmutables cuando sea apropiado.

## 5. Funciones

- Una función debe realizar una tarea concreta.
- Evitar funciones excesivamente largas o con demasiados niveles de anidamiento.
- Reducir parámetros cuando una agrupación coherente mejore la API.
- Evitar efectos secundarios ocultos.
- No realizar operaciones costosas inesperadamente dentro de getters o métodos aparentemente simples.

## 6. Colecciones

- Preferir las APIs funcionales de Dart cuando mejoren la legibilidad.
- Evitar crear colecciones intermedias innecesarias en rutas críticas de rendimiento.
- No modificar una colección mientras se está iterando sobre ella salvo que el patrón sea seguro y explícito.
- Elegir `List`, `Set` y `Map` según la semántica requerida y no por costumbre.

## 7. Async, Future y Stream

- Usar `async`/`await` para código asíncrono cuando facilite la lectura.
- Gestionar explícitamente errores de `Future` y `Stream`.
- Cancelar subscriptions cuando su ciclo de vida termine.
- Evitar operaciones asíncronas sin `await` cuando puedan generar errores no controlados.
- No bloquear el hilo principal con procesamiento pesado.
- Definir el comportamiento ante cancelación, timeout y reintentos cuando sean relevantes.

## 8. Errores y excepciones

- No usar excepciones como flujo normal de negocio si el proyecto dispone de un mecanismo explícito para representar resultados o fallos.
- En arquitecturas que utilicen `fpdart`, mantener patrones coherentes como `Either<Failure, Success>`.
- No ocultar excepciones con `catch` vacíos.
- Añadir contexto útil al error sin incluir información sensible.
- Separar errores técnicos de mensajes destinados al usuario.

## 9. Inmutabilidad

- Preferir `final` frente a `var` cuando una variable no necesita reasignarse.
- Usar `const` cuando el objeto pueda ser constante.
- Evitar estado mutable compartido sin una necesidad clara.
- Mantener las entidades y modelos inmutables cuando encaje con la arquitectura.

## 10. Pattern matching y records

- Usar records, pattern matching y `switch` exhaustivos cuando hagan el código más claro.
- Evitar utilizarlos únicamente por novedad si una construcción sencilla resulta más legible.
- Aprovechar los tipos sellados cuando ayuden a representar estados finitos y exhaustivos.

## 11. Serialización y modelos

- Mantener la conversión JSON aislada de la lógica de negocio.
- Si se utiliza `json_serializable`, mantener los modelos y archivos generados según las convenciones del proyecto.
- No editar manualmente archivos generados.
- Validar datos externos antes de utilizarlos como entidades de dominio.

## 12. Dependencias e inyección

- Evitar dependencias globales ocultas.
- Usar inyección de dependencias cuando facilite testing y desacoplamiento.
- Mantener la configuración de `get_it` o el mecanismo equivalente en un punto claramente definido.
- Las clases deben depender de abstracciones cuando exista una razón arquitectónica para ello.

## 13. Logs y seguridad

- No registrar tokens, contraseñas, claves privadas, información sensible ni respuestas completas que puedan contener datos privados.
- Diferenciar logs de desarrollo y producción.
- No introducir secretos en constantes, código fuente o repositorios.
- Sanitizar información antes de incluirla en logs.

## 14. Testing

- Diseñar el código para poder probarlo sin depender innecesariamente de Flutter o servicios externos.
- Probar casos normales, límites y errores.
- Cubrir especialmente transformaciones de datos, validaciones, casos de uso y estados.
- Evitar tests excesivamente acoplados a detalles internos de implementación.

## 15. Rendimiento

- Evitar asignaciones y conversiones innecesarias en rutas críticas.
- No hacer parsing o procesamiento pesado repetidamente si puede reutilizarse el resultado.
- Usar isolates cuando el procesamiento sea suficientemente costoso como para afectar a la interfaz.
- Medir antes de aplicar optimizaciones complejas.

## 16. Organización y dependencias entre módulos

- Mantener las dependencias dirigidas de forma coherente con la arquitectura.
- Evitar imports circulares.
- Evitar que una feature dependa directamente de detalles internos de otra feature.
- Si el proyecto establece una única entrada pública por feature, respetar ese contrato y no importar archivos internos desde fuera.

## 17. Regla de 4

Cuando el proyecto establezca la **regla de 4**, mantenerla como criterio de organización:

- No permitir que una abstracción o feature exponga innecesariamente múltiples puntos de entrada.
- Agrupar responsabilidades relacionadas de forma coherente.
- Mantener los límites públicos claramente definidos.
- No saltarse estos límites mediante imports internos para ahorrar código.

## 18. Criterio general

El código Dart debe priorizar:

1. Legibilidad.
2. Seguridad de tipos.
3. Inmutabilidad cuando sea apropiada.
4. Testabilidad.
5. Separación de responsabilidades.
6. Manejo explícito de errores.
7. Rendimiento medible.
8. Mantenibilidad.

Estas directrices no sustituyen las decisiones específicas del proyecto. Cuando exista conflicto entre una regla genérica y una decisión documentada del proyecto, debe prevalecer la decisión explícitamente confirmada para ese proyecto.
