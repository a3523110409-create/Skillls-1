# Reglas de Rendimiento (`rules/performance.md`)

Este módulo define reglas diseñadas para eliminar cuellos de botella en la base de datos, escaneos completos de tablas (Full Table Scans), agotamiento de memoria y planes de ejecución subóptimos.

---

## PERF-R01: Proyección Incondicional (`SELECT *`)

### Definición de la Regla
`IF` la sentencia es `SELECT` `AND` proyecta columnas utilizando el comodín `*` o `alias_tabla.*`, `THEN` marcar como violación de severidad **HIGH**.

> **Justification:** `SELECT *` transfiere columnas innecesarias a través de la red, aumenta el consumo de memoria en la base de datos y servidores de aplicación, previene optimizaciones de escaneo de índice cubierto (covering index) y corre el riesgo de romper capas de aplicación cuando las migraciones agregan o reordenan columnas.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
SELECT * FROM TA_ORDENES WHERE FDFECHA_ORDEN >= '2026-01-01';
```

#### Correcto (PASS)
```sql
SELECT FNORDEN_ID, FNUSUARIO_ID, FNMONTO_TOTAL, FDFECHA_ORDEN 
FROM TA_ORDENES 
WHERE FDFECHA_ORDEN >= '2026-01-01';
```

---

## PERF-R06: Protección de Paginación en Consultas Masivas (Uso de `LIMIT`)

### Definición de la Regla
`IF` la sentencia es `SELECT` sobre tablas transaccionales sin cláusula `LIMIT` / `TOP` / `FETCH FIRST` `OR` contiene un límite cosmético (`LIMIT >= 1000000`), `THEN` marcar como violación de severidad **HIGH** (`CRITICAL` si `LIMIT >= 1000000000`).

> **Justificación:** Consultas sin límite o con límites cosméticos excesivos (ej. `LIMIT 1000000000`) provocan que conjuntos masivos de datos se carguen en la memoria de la aplicación, ocasionando errores OutOfMemory (OOM), bloqueos de CPU y consumo excesivo de I/O en la base de datos.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Cláusula LIMIT ausente
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS ORDER BY FDFECHA_CREACION DESC;

-- Evasión por LIMIT cosmético
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS LIMIT 1000000000;
```

#### Correcto (PASS)
```sql
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS ORDER BY FDFECHA_CREACION DESC LIMIT 100;
```

---

## PERF-R09: Cobertura Faltante de Índices en Predicados de Join y Filtro

### Definición de la Regla
`IF` la sentencia une tablas o filtra mediante `WHERE` / `GROUP BY` en columnas sin índices B-Tree o Hash confirmados en los metadatos del esquema, `THEN` marcar como severidad **HIGH** (si se confirma la falta de índice) o **INFO** / `UNKNOWN` (si faltan metadatos del esquema).

> **Justificación:** Consultar columnas no indexadas obliga al optimizador a realizar un escaneo secuencial completo de la tabla ($O(N)$), causando cuellos de botella severos en I/O de disco y bloqueos en cargas concurrentes.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Predicado de búsqueda no indexado (asumiendo que FCCORREO no tiene índice)
SELECT FNUSUARIO_ID, FCNOMBRE FROM TA_USUARIOS WHERE FCCORREO = 'usuario@ejemplo.com';
```

#### Correcto (PASS)
```sql
-- Predicado en Clave Primaria / Columna Indexada
SELECT FNUSUARIO_ID, FCNOMBRE FROM TA_USUARIOS WHERE FNUSUARIO_ID = 502;
```

---

## PERF-R10: Predicados No SARGables y Subconsultas Correlacionadas

### Definición de la Regla
`IF` el predicado `WHERE` envuelve una columna indexada en una función escalar (ej. `YEAR()`, `LOWER()`, `SUBSTRING()`, operaciones aritméticas) `OR` la proyección del `SELECT` utiliza subconsultas correlacionadas que se evalúan por cada fila, `THEN` marcar como violación de severidad **HIGH**.

> **Justificación:** Envolver columnas en funciones escalares invalida los índices B-Tree (No SARGable), forzando un escaneo completo. Las subconsultas correlacionadas introducen una complejidad $O(N)$ al reejecutarse por cada fila de la consulta externa.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Función envolviendo columna indexada (No SARGable)
SELECT FNORDEN_ID FROM TA_ORDENES WHERE YEAR(FDFECHA_ORDEN) = 2026;

-- Subconsulta correlacionada en proyección SELECT
SELECT u.FNUSUARIO_ID, 
       (SELECT COUNT(*) FROM TA_ORDENES o WHERE o.FNUSUARIO_ID = u.FNUSUARIO_ID) AS total_ordenes
FROM TA_USUARIOS u;
```

#### Correcto (PASS)
```sql
-- Filtro por rango conservando la columna pura (SARGable)
SELECT FNORDEN_ID FROM TA_ORDENES 
WHERE FDFECHA_ORDEN >= '2026-01-01' AND FDFECHA_ORDEN < '2027-01-01';

-- Agregación mediante JOIN explícito
SELECT u.FNUSUARIO_ID, COUNT(o.FNORDEN_ID) AS total_ordenes
FROM TA_USUARIOS u
LEFT JOIN TA_ORDENES o ON u.FNUSUARIO_ID = o.FNUSUARIO_ID
GROUP BY u.FNUSUARIO_ID;
```

---

## PERF-R12: [REGLA PROPIA] Coerción Implícita de Tipos de Datos en Predicados

### Definición de la Regla
`IF` un predicado de join o cláusula `WHERE` compara una columna contra un literal o columna de tipo de dato diferente (ej. columna de texto comparada con entero `FCCUENTA_NUMERO = 987654321` o columna numérica comparada con texto `'500'`), `THEN` marcar como violación de severidad **HIGH**.

> **Justificación:** Cuando los tipos de datos no coinciden, el motor SQL convierte los datos de cada fila dinámicamente durante la ejecución. Esta conversión implícita invalida los índices existentes y consume ciclos de CPU considerables.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- FCCUENTA_NUMERO es VARCHAR(50), pero se filtra con literal entero
SELECT FNUSUARIO_ID FROM TA_CUENTAS WHERE FCCUENTA_NUMERO = 987654321;
```

#### Correcto (PASS)
```sql
-- Filtrado con tipo de literal texto coincidente
SELECT FNUSUARIO_ID FROM TA_CUENTAS WHERE FCCUENTA_NUMERO = '987654321';
```
