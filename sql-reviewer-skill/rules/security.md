# Reglas de Seguridad (`rules/security.md`)

Este módulo define reglas deterministas y enfocadas en la intención para la revisión de consultas SQL. Los hallazgos de seguridad tienen la máxima prioridad en la revisión de código.

---

## SEC-R02: Filtrado Incondicional o Cosmético en `UPDATE` / `DELETE`

### Definición de la Regla
`IF` la sentencia es `UPDATE` o `DELETE` `AND` (`WHERE` está ausente `OR` la cláusula `WHERE` se evalúa como verdaderamente incondicional como `1=1`, `0=0`, `'a'='a'`, `TRUE` o patrón comodín `FCCORREO LIKE '%'`), `THEN` marcar como violación de severidad **CRITICAL**.

> **Justificación:** Ejecutar sentencias `DELETE` u `UPDATE` sin una cláusula `WHERE` selectiva resulta en la modificación o eliminación inmediata de toda la tabla. Los filtros cosméticos como `WHERE 1=1` o `WHERE FCCORREO LIKE '%'` son técnicas deliberadas de evasión de patrones que superan verificaciones simples por regex causando una pérdida catastrófica idéntica.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Cláusula WHERE ausente
DELETE FROM TA_USUARIOS;

-- Filtro cosmético (Siempre Verdadero)
DELETE FROM TA_USUARIOS WHERE 1 = 1;

-- Filtro comodín que selecciona el 100% de las filas
UPDATE TA_USUARIOS SET FCROL = 'ADMINISTRA' WHERE FCCORREO LIKE '%';
```

#### Correcto (PASS)
```sql
-- Filtrado por clave primaria específica
DELETE FROM TA_USUARIOS WHERE FNUSUARIO_ID = 4821;

-- Actualización acotada parametrizada
UPDATE TA_USUARIOS SET FCROL = 'ADMINISTRA' WHERE FNUSUARIO_ID = :usuarioId AND FCESTADO = 'ACTIVO';
```

---

## SEC-R04: Concatenación Dinámica de Cadenas SQL (Riesgo de Inyección SQL)

### Definición de la Regla
`IF` la sentencia construye consultas SQL mediante concatenación de cadenas (`+`, `||`, `CONCAT()`) usando variables o cadenas de entrada externa no sanitizadas, `THEN` marcar como violación de severidad **CRITICAL**.

> **Justificación:** La concatenación de cadenas permite a los atacantes inyectar fragmentos SQL maliciosos, evadiendo la autenticación, extrayendo el contenido de la base de datos o ejecutando comandos administrativos. Todas las entradas variables deben usar sentencias preparadas con parámetros vinculados (bind parameters).

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Concatenación de cadenas con variable de entrada
SELECT * FROM TA_USUARIOS WHERE FCCORREO = '' + entrada_usuario + '';

-- Función CONCAT con variable dinámica
SELECT FCNOMBRE, FCCORREO FROM TA_USUARIOS WHERE FCROL = CONCAT('ROL_', rol_entrada);
```

#### Correcto (PASS)
```sql
-- Sentencia preparada parametrizada
SELECT FNUSUARIO_ID, FCNOMBRE, FCCORREO FROM TA_USUARIOS WHERE FCCORREO = :correo;

-- Parámetro vinculado posicional
SELECT FCNOMBRE, FCCORREO FROM TA_USUARIOS WHERE FCROL = $1;
```

---

## SEC-R11: [REGLA PROPIA] Cambios Destructivos de Esquema No Seguros y Evasión de Borrado Lógico

### Definición de la Regla
`IF` la sentencia ejecuta `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`, `ALTER TABLE ... DROP COLUMN` `OR` `DELETE` físico en tablas configuradas para borrado lógico (`fdes_eliminado` o `fdeliminado_at` presente), `THEN` marcar como severidad **CRITICAL** (para DDL) o **HIGH** (para DELETE físico).

> **Justificación:** El DDL destructivo omite el rollback transaccional en muchos motores y elimina permanentemente la estructura/datos. El `DELETE` físico en tablas auditadas con borrado lógico corrompe los rastros de auditoría y los reportes analíticos históricos.

### Ejemplos de Código

#### Incorrecto (FAIL)
```sql
-- Truncado directo de tabla
TRUNCATE TABLE TA_TRANSACCIONES;

-- Borrado físico en tabla auditada con borrado lógico
DELETE FROM TA_USUARIOS WHERE FNUSUARIO_ID = 102;
```

#### Correcto (PASS)
```sql
-- Patrón de actualización para borrado lógico
UPDATE TA_USUARIOS SET FDES_ELIMINADO = 1, FDELIMINADO_AT = CURRENT_TIMESTAMP WHERE FNUSUARIO_ID = 102;
```
