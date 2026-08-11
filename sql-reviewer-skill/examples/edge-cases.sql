-- =============================================================================
-- EJEMPLOS: CASOS DE BORDE Y CONSULTAS ADVERSARIALES EN SQL
-- Estas sentencias parecen cumplir superficialmente las reglas de sintaxis (ej. incluyen
-- cláusulas WHERE o parámetros LIMIT), pero emplean técnicas de evasión o fallos semánticos
-- que degradan el rendimiento o comprometen la seguridad de los datos.
-- =============================================================================

-- Caso de Borde 1: Evasión por cláusula WHERE cosmética (Se evalúa como TRUE para todas las filas)
-- Contiene superficialmente un WHERE, pero evade la modificación acotada.
DELETE FROM TA_USUARIOS WHERE 1 = 1;

-- Caso de Borde 2: Evasión por cláusula LIMIT cosmética (Parámetro de límite astronómico)
-- Incluye superficialmente LIMIT, pero 1 Billón no ofrece ninguna protección de memoria OOM.
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS LIMIT 1000000000;

-- Caso de Borde 3: Evasión por filtro comodín cosmético
-- Incluye superficialmente WHERE con LIKE, pero '%' coincide con el 100% de registros no nulos.
UPDATE TA_USUARIOS SET FCROL = 'ADMINISTRA' WHERE FCCORREO LIKE '%';

-- Caso de Borde 4: Búsqueda insensible a mayúsculas No SARGable
-- Consulta superficialmente válida, pero la función LOWER() invalida el índice B-Tree en FCCORREO.
SELECT FNUSUARIO_ID, FCNOMBRE FROM TA_USUARIOS WHERE LOWER(FCCORREO) = 'admin@empresa.com' LIMIT 10;

-- Caso de Borde 5: Subconsulta correlacionada N+1 en proyección SELECT
-- Incluye LIMIT 50, pero la subconsulta se reevalúa por cada fila creando sobrecarga O(N).
SELECT u.FNUSUARIO_ID, u.FCNOMBRE_USUARIO, 
       (SELECT COUNT(*) FROM TA_ORDENES o WHERE o.FNUSUARIO_ID = u.FNUSUARIO_ID) AS total_ordenes
FROM TA_USUARIOS u
LIMIT 50;
