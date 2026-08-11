# SQL Reviewer (Revisor de SQL)

## Purpose (Propósito)
La skill `sql-reviewer` proporciona un marco de revisión de código automatizado, riguroso y determinista para sentencias SQL destinadas a entornos de producción. Aplica las mejores prácticas de la industria en seguridad, rendimiento, integridad de datos y convenciones de nombres mediante la evaluación de consultas contra reglas condicionales explícitas (`IF ... THEN ...`). Minimiza falsos positivos y elimina el contexto alucinado al declarar escenarios ambiguos o con falta de contexto como `INFO` o `UNKNOWN`.

## When to activate (Cuándo activar)
Activa esta skill en cualquiera de los siguientes escenarios:
1. El usuario solicita una revisión de código SQL, auditoría, escaneo de seguridad o análisis de rendimiento de consultas.
2. El usuario proporciona un archivo `.sql`, fragmento SQL, script de migración o sentencia DML/DDL pidiendo comentarios u optimización.
3. El usuario solicita verificar el cumplimiento de código SQL contra las mejores prácticas antes de la aprobación de un pull request o despliegue.
4. Hooks de pre-commit o workflows de CI/CD automatizados requieren una evaluación estructurada de SQL.

## When NOT to activate (Cuándo NO activar)
La skill `sql-reviewer` debe abstenerse explícitamente de activarse en los siguientes escenarios:
1. **Entrada que no es SQL**: El input consiste en código no SQL (ej. código ORM en Python como SQLAlchemy/Prisma, scripts bash, JSON, consultas NoSQL como pipelines de agregación en MongoDB), a menos que las cadenas SQL puras estén aisladas explícitamente para su revisión.
2. **DDL de motores no soportados**: El input contiene DDL propietario o extensiones para motores fuera de los estándares ANSI SQL / PostgreSQL / MySQL / Oracle (ej. cuerpos de paquetes PL/SQL, binarios de procedimientos almacenados extendidos T-SQL) sin un contexto de sintaxis de consulta estándar.
3. **Fragmentos incompletos o truncados sintácticamente**: El input contiene fragmentos de texto arbitrarios, cláusulas parciales (ej. solo `LEFT JOIN tabla_b ON`) o pseudocódigo sin contexto completo de la sentencia.
4. **Pull Requests ya aprobados sin contexto de intención**: El input es un diff histórico o log de base de datos presentado únicamente para documentación o archivo sin intención de modificar o auditar la lógica del código.

## Inputs (Entradas)
- **Entrada Principal**: Script SQL puro, archivo de migración, DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) o DDL (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`).
- **Contexto Opcional**: Motor de Base de Datos objetivo (PostgreSQL, MySQL, Oracle, SQL Server), definiciones de Esquema/DDL, definiciones de índices, recuento de filas de tablas y metadatos de intención.

## Procedure (Procedimiento)
Ejecuta el siguiente algoritmo de evaluación determinista para cada solicitud de revisión SQL:

1. **Parseo y Validación de Entrada**:
   - Parsear la cadena de entrada en sentencias SQL discretas.
   - Verificar validez sintáctica. Si existen errores de sintaxis, detener la evaluación y activar `Failure Handling` (Sección 11).
2. **Clasificación de Sentencias**:
   - Clasificar cada sentencia por categoría: DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`), DDL (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`) o Gestión de Transacciones (`COMMIT`, `ROLLBACK`).
3. **Evaluación de Disponibilidad de Contexto**:
   - Verificar si los metadatos externos necesarios (índices del esquema, tamaño de tabla, configuración de borrado lógico) están presentes. Si faltan, marcar las reglas dependientes del contexto como `UNKNOWN` o `INFO` en lugar de asumir cumplimiento o incumplimiento.
4. **Evaluación de Reglas (Bucle por sentencia)**:
   - Evaluar cada sentencia contra las 12 reglas explícitas definidas en la Sección 6 (`R01` a `R12`).
   - Evaluar tanto coincidencias de patrones superficiales COMO la intención semántica (ej. detectar `WHERE 1=1` cosmético o `LIMIT 1000000000` cosmético).
5. **Asignación de Severidad y Resolución de Conflictos**:
   - Asignar niveles de severidad (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`) basados estrictamente en criterios objetivos definidos en la Sección 7.
   - Aplicar la prioridad de resolución de conflictos (Seguridad > Integridad de Datos > Rendimiento > Convenciones) definida en la Sección 6.13.
6. **Formato de Salida**:
   - Generar un reporte estructurado en Markdown adhiriéndose estrictamente a la plantilla de `Expected output` de la Sección 8.

## Rules (Reglas)

### R01: Recuperación Selectiva de Columnas (No `SELECT *`)
- **Condición**: `IF` la sentencia es `SELECT` `AND` utiliza comodines (`*` o `tabla.*`) en la proyección de columnas.
- **Acción**: `THEN` marcar como violación de severidad `HIGH`. Requerir listado explícito de columnas.
- **Justificación**: Evita I/O innecesario, sobrecarga de memoria, latencia de red y la ruptura de contratos de API cuando ocurren cambios en el esquema.

### R02: Ejecución Segura de `UPDATE` / `DELETE` (Sin Filtros Incondicionales o Cosméticos)
- **Condición**: `IF` la sentencia es `UPDATE` o `DELETE` `AND` (`WHERE` no existe `OR` la cláusula `WHERE` se evalúa como un verdadero incondicional como `1=1`, `0=0`, `'a'='a'` o `FCCORREO LIKE '%')`.
- **Acción**: `THEN` marcar como violación de severidad `CRITICAL`. Bloquear la ejecución inmediatamente.
- **Justificación**: Previene el borrado masivo catastrófico de datos o actualizaciones no intencionadas en toda la tabla. Los filtros cosméticos diseñados para evadir verificaciones simples se clasifican como vulnerabilidades de seguridad por evasión de intención.

### R03: Protecciones de DDL Destructivo
- **Condición**: `IF` la sentencia contiene `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE` o `ALTER TABLE ... DROP COLUMN`.
- **Acción**: `THEN` marcar como violación de severidad `CRITICAL`. Requerir etiqueta de aprobación explícita de migración y verificación de respaldo.
- **Justificación**: Las operaciones de pérdida permanente e irrecuperable de datos deben requerir aprobación manual de alto nivel.

### R04: Mitigación de Inyección SQL Dinámica
- **Condición**: `IF` la sentencia SQL contiene concatenación de cadenas (ej. `+`, `||`, `CONCAT()`) involucrando variables de entrada externa de usuario o cadenas de consulta dinámicas no parametrizadas.
- **Acción**: `THEN` marcar como violación de severidad `CRITICAL`. Requerir consultas parametrizadas (`?`, `:param`, `$1`).
- **Justificación**: Previene la ejecución remota de código, la toma de control de la base de datos y el acceso no autorizado mediante ataques de inyección SQL.

### R05: Convenciones de Nombres en la Base de Datos
- **Condición**: `IF` los identificadores de tablas, columnas o índices no siguen las convenciones de prefijos (ej. `TA_` para tablas, `FC` para cadenas/varchar, `FN` para numéricos, `FD` para fechas) `OR` utilizan palabras reservadas, camelCase, espacios o caracteres especiales.
- **Acción**: `THEN` marcar como violación de severidad `LOW`.
- **Justificación**: Mantiene la legibilidad entre equipos, previene colisiones con palabras reservadas del motor y asegura consistencia en los objetos.

### R06: Control de Límite en Consultas Masivas (Sin `LIMIT` Faltante o Cosmético)
- **Condición**: `IF` la sentencia es `SELECT` sin cláusula `LIMIT`/`TOP`/`FETCH FIRST` `OR` contiene un límite cosmético (`LIMIT >= 1000000`).
- **Acción**: `THEN` marcar como violación de severidad `HIGH` (`CRITICAL` si el límite es >= 1,000,000,000).
- **Justification**: Los límites ausentes o falsos pueden colapsar servidores de aplicación con errores OutOfMemory y agotar el buffer pool de la base de datos.

### R07: Manejo Estricto de Comparaciones con `NULL`
- **Condición**: `IF` el predicado de filtrado o join compara `NULL` usando operadores de igualdad o desigualdad (`= NULL`, `<> NULL`, `!= NULL`).
- **Acción**: `THEN` marcar como violación de severidad `MEDIUM`. Requerir `IS NULL` o `IS NOT NULL`.
- **Justificación**: En ANSI SQL (Lógica Trivalente 3VL), las comparaciones con `NULL` usando `=` o `!=` se evalúan como `UNKNOWN`, haciendo que las consultas devuelvan cero filas silenciosamente.

### R08: Elección Óptima de Tipos de Datos
- **Condición**: `IF` las llaves primarias o foráneas utilizan tipos de texto variable (`VARCHAR`) sin justificación de UUID `OR` valores numéricos almacenados como texto `OR` fechas/marcas de tiempo almacenadas como texto.
- **Acción**: `THEN` marcar como violación de severidad `MEDIUM`.
- **Justificación**: Los tipos de datos ineficientes aumentan el tamaño de almacenamiento en disco, degradan la velocidad de búsqueda en índices y desactivan optimizaciones en memoria.

### R09: Detección de Índices Faltantes en Predicados de Join y Filtro
- **Condición**: `IF` la consulta realiza `JOIN`, `WHERE` o `GROUP BY` en columnas sin cobertura de índice confirmada en los metadatos del esquema.
- **Acción**: `THEN` marcar como violación de severidad `HIGH` si se confirma la ausencia de índice, `OR` marcar como `INFO` con estado `UNKNOWN` si falta el contexto del esquema.
- **Justificación**: Las columnas de predicado sin índice forzan escaneos secuenciales completos de tabla (Full Table Scan), aumentando el I/O en disco y la latencia exponencialmente.

### R10: Detección de Anti-Patrones de Rendimiento (No SARGables y Subconsultas Correlacionadas)
- **Condición**: `IF` la cláusula `WHERE` aplica funciones escalares sobre columnas indexadas (ej. `WHERE YEAR(fd_fecha) = 2026` o `LOWER(fc_correo) = '...'`) `OR` utiliza subconsultas correlacionadas en la proyección del `SELECT` (patrón `N+1`).
- **Acción**: `THEN` marcar como violación de severidad `HIGH`.
- **Justificación**: Las funciones en columnas de predicado invalidan los árboles B-Tree (No SARGable), forzando escaneos completos. Las subconsultas correlacionadas se ejecutan por cada fila, resultando en una complejidad $O(N)$.

### R11: [REGLA PROPIA] Integridad Referencial en Cascade de FK y Borrado Lógico (Soft-Delete)
- **Condición**: `IF` se ejecuta `ALTER TABLE ... DROP CONSTRAINT` o `DELETE` en una tabla con relaciones de clave foránea sin especificar estrategia en cascada `OR` se mezcla un patrón de borrado lógico (`fdes_eliminado` / `fdeliminado_at`) con `DELETE` físico.
- **Acción**: `THEN` marcar como violación de severidad `HIGH`.
- **Justificación**: Previene registros huérfanos en tablas hijas y la destrucción accidental de registros de auditoría de borrado lógico.

### R12: [REGLA PROPIA] Coerción Implícita de Tipos de Datos en Predicados
- **Condición**: `IF` un predicado de join o filtro compara columnas/valores de tipos de datos no coincidentes (ej. `FCCUENTA_NUMERO = 12345` o `FNNUMERO_ID = '123'`).
- **Acción**: `THEN` marcar como violación de severidad `HIGH`.
- **Justificación**: La conversión implícita obliga al motor a castear cada fila dinámicamente durante la ejecución, desactivando los índices y elevando el consumo de CPU.

## Rule Conflict Resolution (Resolución de Conflictos entre Reglas)
Cuando una misma consulta viola múltiples reglas simultáneamente, la prioridad de reporte y la asignación de severidad siguen un orden jerárquico estricto:

1. **Prioridad 1: Violaciones de Seguridad (`R02`, `R04`)** — Inyecciones SQL dinámicas y cláusulas `WHERE` cosméticas en `DELETE`/`UPDATE` sobrescriben a cualquier otro hallazgo.
2. **Prioridad 2: Integridad de Datos y DDL Destructivo (`R03`, `R07`, `R11`)** — Pérdida irrecuperable de datos o fallos lógicos (ej. `= NULL`).
3. **Prioridad 3: Anti-patrones de Rendimiento (`R01`, `R06`, `R09`, `R10`, `R12`)** — Latencia de consulta, índices faltantes, filtros No SARGables y límites cosméticos.
4. **Prioridad 4: Convenciones y Estándares (`R05`, `R08`)** — Nombres de identificadores y preferencias menores en tipos de datos.

*Regla: El estado general de la consulta toma la severidad máxima de cualquier hallazgo individual detectado.*

## Severity Levels (Niveles de Severidad)

| Severidad | Definición y Criterio de Decisión | Acción Requerida |
| :--- | :--- | :--- |
| **CRITICAL** | Alta probabilidad de pérdida de datos, compromiso de la base de datos o caída del servicio (ej. `DELETE` sin `WHERE` válido, inyección SQL, DDL destructivo, `LIMIT >= 1000000000` cosmético). | Bloquear despliegue inmediatamente. Refactorización obligatoria. |
| **HIGH** | Degradación de rendimiento, sobrecarga de memoria o escaneo completo de tablas grandes (ej. `SELECT *`, `LIMIT` ausente, filtros No SARGables, falta de índices en FK). | Requiere corrección antes de fusionar a producción. |
| **MEDIUM** | Errores lógicos o patrones de datos subóptimos (ej. `= NULL`, casteo implícito de tipos, tipos de datos subóptimos). | Corrección recomendada durante el sprint actual. |
| **LOW** | Formato de código, no cumplimiento de convenciones de nombres, falta de alias. | Advertencia menor, corregir a discreción del desarrollador. |
| **INFO** | Ambigüedad por falta de contexto de esquema/índices/volumen. Requiere verificación del usuario. | Solicitar contexto al usuario; no bloquear el pipeline. |

## Expected Output (Formato de Salida Esperado)
Todas las revisiones DEBEN emitir un reporte Markdown formateado exactamente de la siguiente manera:

```markdown
# Reporte de Revisión de Código SQL

## Resumen
- **Resultado General**: [PASSED | ACTION REQUIRED | INSUFFICIENT CONTEXT]
- **Severidad Máxima**: [CRITICAL | HIGH | MEDIUM | LOW | INFO]
- **Total de Hallazgos**: [Cantidad]

## Detalle de Hallazgos

| Línea | Regla Violada | Severidad | Explicación Técnica | Remediación Recomendada |
| :--- | :--- | :--- | :--- | :--- |
| Línea N | R0X: Nombre de la Regla | SEVERIDAD | Descripción técnica del riesgo. | Corrección específica de código SQL. |

## Solicitudes de Contexto / Declaraciones UNKNOWN
- [Listar metadatos faltantes de esquema, índices o volumen necesarios para completar el análisis]
```

## Validation (Autoverificación)
Antes de responder, la skill ejecuta una lista de verificación interna de autoverificación:
- [ ] ¿Se evaluaron las 12 reglas (`R01`-`R12`) contra cada sentencia?
- [ ] ¿Se probaron activamente patrones de evasión cosmética (`WHERE 1=1`, `LIMIT 1000000000`, `LIKE '%'`)?
- [ ] ¿Cada hallazgo está justificado con una explicación técnica del riesgo?
- [ ] ¿Los elementos contextuales faltantes están marcados como `INFO`/`UNKNOWN` en lugar de alucinados?
- [ ] ¿La salida coincide estrictamente con la plantilla de la Sección 8?

## Failure Handling (Manejo de Fallos)
1. **Sintaxis SQL Inválida**: Si la entrada no se puede parsear, devolver: `[ERROR] Sintaxis SQL Inválida en Línea X: No se puede parsear la consulta. Por favor verifique la sintaxis SQL.`
2. **Dialecto de Motor Desconocido**: Devolver `[WARNING] Dialecto de Motor Desconocido: Evaluado según reglas relacionales estándar / ANSI SQL.`
3. **Entrada Vacía**: Devolver `[ERROR] Entrada Vacía: No se proporcionaron sentencias SQL para evaluar.`
4. **Falta de Contexto (Esquema/Índices/Volumen de Datos)**: NO inventar suposiciones. Declarar los hallazgos dependientes del esquema como `Severidad: INFO` con estado `UNKNOWN` y solicitar al usuario: `[INFO] No se puede determinar la cobertura de índice para la tabla TA_USUARIOS columna FCCORREO. Por favor proporcione las definiciones de índices del esquema.`

## Deterministic vs. Model-dependent (Determinista vs. Dependiente del Modelo)

| Componente / Regla | Clasificación | Mecanismo de Ejecución |
| :--- | :--- | :--- |
| **R01 (`SELECT *`)** | Determinista | Proyección AST / Coincidencia de patrones Regex para comodín `*`. |
| **R02 (`UPDATE/DELETE` seguro)** | Híbrido (Determinista + Modelo) | Coincidencia de patrones para `WHERE` ausente + análisis semántico para detectar cláusulas cosméticas (`1=1`, `LIKE '%'`). |
| **R03 (DDL Destructivo)** | Determinista | Coincidencia de palabras clave (`DROP`, `TRUNCATE`, `ALTER ... DROP`). |
| **R04 (Inyección SQL)** | Híbrido | Detección de operadores de concatenación de cadenas + rastreo semántico del flujo de variables externas. |
| **R05 (Convenciones de Nombres)** | Determinista | Coincidencia de prefijos de identificadores (`TA_`, `FC`, `FN`, `FD`) con expresiones regulares. |
| **R06 (`LIMIT` obligatorio)** | Híbrido | Verificación AST para presencia de `LIMIT` + evaluación numérica para límites cosméticos (>= 1,000,000). |
| **R07 (Comparaciones con `NULL`)**| Determinista | Coincidencia de Regex/AST para `= NULL` o `!= NULL`. |
| **R08 (Tipos de Datos)** | Determinista | Coincidencia de definiciones en el esquema (`VARCHAR` en PKs, fechas almacenadas como texto). |
| **R09 (Índices Faltantes)** | Dependiente del Modelo | Cruzamiento de predicados de consulta con definiciones de índices del esquema proporcionadas en el contexto. |
| **R10 (Anti-Patrones de Rendimiento)**| Dependiente del Modelo | Identificación de funciones escalares sobre columnas indexadas y detección de alias de subconsultas correlacionadas. |
| **R11 (Borrado Lógico e Integridad)**| Dependiente del Modelo | Inferencia de la estrategia de eliminación (`fdes_eliminado`) frente al uso de `DELETE` físico. |
| **R12 (Coerción Implícita de Tipos)**| Determinista | Verificación de compatibilidad entre tipos de datos del lado izquierdo y derecho en predicados. |
