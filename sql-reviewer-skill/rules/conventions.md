# Reglas de Convenciones (`rules/conventions.md`)

Este módulo define reglas de mantenibilidad, cumplimiento de estándares y corrección lógica para el diseño de esquemas y consultas en la base de datos.

---

## CONV-R05: Convenciones de Nombres y Palabras Reservadas

### Definición de la Regla
`IF` los objetos del esquema (tablas, columnas, índices) no siguen los prefijos de identificadores del sistema (`TA_` para Tablas, `FC` para Cadenas/VARCHAR, `FN` para Numéricos, `FD` para Fechas/Timestamps) `OR` utilizan palabras reservadas de SQL (ej. `USER`, `ORDER`, `GROUP`, `KEY`), caracteres especiales, camelCase o espacios, `THEN` marcar como violación de severidad **LOW**.

> **Justificación:** Los prefijos estandarizados comunican inmediatamente el tipo de dato a los desarrolladores, previenen errores de sintaxis causados por palabras reservadas y aseguran consistencia entre motores de bases de datos.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Palabra reservada 'USER' no escapada y nombre de columna en camelCase
CREATE TABLE usuarios (
    usuarioId INT,
    user VARCHAR(100)
);
```

#### Correcto (PASS)
```sql
CREATE TABLE TA_USUARIOS (
    FNUSUARIO_ID INT PRIMARY KEY,
    FCNOMBRE_USUARIO VARCHAR(100) NOT NULL
);
```

---

## CONV-R07: Sintaxis de Comparación con NULL bajo Lógica Trivalente

### Definición de la Regla
`IF` el predicado de filtrado compara `NULL` utilizando operadores de igualdad o desigualdad (`= NULL`, `<> NULL`, `!= NULL`), `THEN` marcar como violación de severidad **MEDIUM**.

> **Justificación:** Bajo la Lógica Trivalente (3VL) de ANSI SQL, `NULL = NULL` y `valor = NULL` se evalúan como `UNKNOWN` en lugar de `TRUE` o `FALSE`. Utilizar `= NULL` o `!= NULL` en cláusulas `WHERE` resulta silenciosamente en cero filas devueltas.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Comparación de igualdad errónea con NULL
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS WHERE FDELIMINADO_AT = NULL;

SELECT FNUSUARIO_ID FROM TA_USUARIOS WHERE FCESTADO != NULL;
```

#### Correcto (PASS)
```sql
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS WHERE FDELIMINADO_AT IS NULL;

SELECT FNUSUARIO_ID FROM TA_USUARIOS WHERE FCESTADO IS NOT NULL;
```

---

## CONV-R08: Elección de Tipos de Datos y Representación de Entidades

### Definición de la Regla
`IF` las columnas de clave primaria o foránea utilizan `VARCHAR` sin justificación de UUID `OR` valores numéricos almacenados como texto `OR` marcas de tiempo almacenadas como texto sin formato, `THEN` marcar como violación de severidad **MEDIUM**.

> **Justificación:** Los tipos de datos desalineados aumentan el consumo de disco, degradan la efectividad de la memoria en operaciones de join y previenen optimizaciones nativas de fechas y cálculos numéricos.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
CREATE TABLE TA_PAGOS (
    FCPAGO_ID VARCHAR(50) PRIMARY KEY, -- Secuencia de enteros almacenada como VARCHAR
    FCRECIBO_FECHA VARCHAR(30)          -- Marca de tiempo almacenada como texto
);
```

#### Correcto (PASS)
```sql
CREATE TABLE TA_PAGOS (
    FNPAGO_ID INT AUTO_INCREMENT PRIMARY KEY,
    FDPAGO_FECHA TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
