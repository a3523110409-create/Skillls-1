-- =============================================================================
-- EJEMPLOS: SENTENCIAS SQL INVÁLIDAS
-- Cada consulta a continuación viola deliberadamente una o más reglas de R01 a R12.
-- =============================================================================

-- Sentencia 1: Viola R01 (SELECT *) y R06 (LIMIT ausente)
SELECT * FROM TA_USUARIOS;

-- Sentencia 2: Viola R02 (DELETE sin cláusula WHERE) [CRITICAL]
DELETE FROM TA_USUARIOS;

-- Sentencia 3: Viola R03 (DDL destructivo TRUNCATE) [CRITICAL]
TRUNCATE TABLE TA_TRANSACCIONES;

-- Sentencia 4: Viola R04 (Inyección SQL por concatenación de cadenas) [CRITICAL]
SELECT FCCORREO, FCROL FROM TA_USUARIOS WHERE FCNOMBRE = '' + entrada_nombre + '';

-- Sentencia 5: Viola R05 (Convenciones de nombres: camelCase, palabra reservada 'user', sin prefijo TA_)
CREATE TABLE usuarios (
    usuarioId INT,
    user VARCHAR(50)
);

-- Sentencia 6: Viola R07 (Comparación errónea con NULL usando =)
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS WHERE FDELIMINADO_AT = NULL;

-- Sentencia 7: Viola R08 (Mala elección de tipos de datos: entero guardado como VARCHAR, fecha como VARCHAR)
CREATE TABLE TA_BITACORA (
    FCBITACORA_ID VARCHAR(50) PRIMARY KEY,
    FCBITACORA_FECHA VARCHAR(50)
);

-- Sentencia 8: Viola R10 (Función escalar No SARGable envolviendo columna de fecha indexada)
SELECT FNORDEN_ID, FNMONTO_TOTAL FROM TA_ORDENES WHERE YEAR(FDFECHA_ORDEN) = 2026;

-- Sentencia 9: Viola R11 [REGLA PROPIA] (DELETE físico en tabla con columna de borrado lógico)
DELETE FROM TA_USUARIOS WHERE FNUSUARIO_ID = 505;

-- Sentencia 10: Viola R12 [REGLA PROPIA] (Coerción implícita: columna VARCHAR comparada con entero)
SELECT FNCUENTA_ID FROM TA_CUENTAS WHERE FCCUENTA_NUMERO = 998877;
