-- =============================================================================
-- EJEMPLOS: SENTENCIAS SQL VÁLIDAS
-- Estas sentencias cumplen estrictamente con todas las reglas de seguridad,
-- rendimiento, integridad y convenciones de nombres. Producen 0 hallazgos.
-- =============================================================================

-- 1. SELECT acotado con proyección explícita de columnas
SELECT FNUSUARIO_ID, FCNOMBRE_USUARIO, FCCORREO, FDFECHA_CREACION
FROM TA_USUARIOS
WHERE FCESTADO = 'ACTIVO'
ORDER BY FDFECHA_CREACION DESC
LIMIT 50;

-- 2. UPDATE DML seguro parametrizado con filtro por clave primaria
UPDATE TA_USUARIOS
SET FCNOMBRE_USUARIO = :nombreUsuario,
    FDFECHA_ACTUALIZACION = CURRENT_TIMESTAMP
WHERE FNUSUARIO_ID = :usuarioId 
  AND FDES_ELIMINADO = 0;

-- 3. Consulta de alto rendimiento SARGable por rango de fechas con predicado IS NULL
SELECT FNORDEN_ID, FNUSUARIO_ID, FNMONTO_TOTAL
FROM TA_ORDENES
WHERE FDFECHA_ORDEN >= '2026-01-01' 
  AND FDFECHA_ORDEN < '2026-02-01'
  AND FDCANCELADO_AT IS NULL
ORDER BY FDFECHA_ORDEN ASC
LIMIT 100;

-- 4. Actualización limpia de borrado lógico evitando DELETE físico destructivo
UPDATE TA_PRODUCTOS
SET FDES_ELIMINADO = 1,
    FDELIMINADO_AT = CURRENT_TIMESTAMP
WHERE FNPRODUCTO_ID = :productoId
  AND FDES_ELIMINADO = 0;

-- 5. Agregación explícita con JOIN y coincidencia de tipos de datos
SELECT u.FNUSUARIO_ID, u.FCNOMBRE_USUARIO, COUNT(o.FNORDEN_ID) AS FNTOTAL_ORDENES
FROM TA_USUARIOS u
INNER JOIN TA_ORDENES o ON u.FNUSUARIO_ID = o.FNUSUARIO_ID
WHERE u.FCESTADO = 'ACTIVO'
GROUP BY u.FNUSUARIO_ID, u.FCNOMBRE_USUARIO
LIMIT 200;
