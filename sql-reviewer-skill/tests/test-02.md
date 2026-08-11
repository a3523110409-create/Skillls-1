# Pruebas Test 02: Evaluación de Errores Evidentes

## Input (Entrada)
```sql
SELECT * FROM TA_USUARIOS WHERE FDELIMINADO_AT = NULL;
DELETE FROM TA_ORDENES;
```

## Expected behavior (Comportamiento Esperado)
La skill detecta múltiples violaciones evidentes:
1. `R01`: Proyección incondicional comodín `SELECT *` (`HIGH`).
2. `R07`: Comparación inválida `= NULL` (`MEDIUM`).
3. `R02` & `R06`: `DELETE FROM TA_ORDENES` incondicional sin cláusula `WHERE` (`CRITICAL`).
Resultado general reportado como `ACTION REQUIRED` con severidad máxima `CRITICAL`.

## Actual behavior (Comportamiento Real)
```markdown
# Reporte de Revisión de Código SQL

## Resumen
- **Resultado General**: ACTION REQUIRED
- **Severidad Máxima**: CRITICAL
- **Total de Hallazgos**: 3

## Detalle de Hallazgos

| Línea | Regla Violada | Severidad | Explicación Técnica | Remediación Recomendada |
| :--- | :--- | :--- | :--- | :--- |
| Línea 1 | R01: Proyección Selectiva | HIGH | La consulta utiliza `SELECT *`, obteniendo columnas innecesarias y aumentando la carga de red/memoria. | Especificar explícitamente las columnas requeridas: `SELECT FNUSUARIO_ID, FCCORREO...`. |
| Línea 1 | R07: Comparación con NULL | MEDIUM | El predicado compara `FDELIMINADO_AT = NULL`. En ANSI SQL 3VL, `= NULL` se evalúa como UNKNOWN, devolviendo 0 filas. | Cambiar operador a `IS NULL`: `WHERE FDELIMINADO_AT IS NULL`. |
| Línea 2 | R02: Filtro DELETE Seguro | CRITICAL | La sentencia `DELETE FROM TA_ORDENES` no contiene una cláusula `WHERE`, lo que provocará el borrado completo de la tabla TA_ORDENES. | Agregar cláusula `WHERE` selectiva: `WHERE FNORDEN_ID = :ordenId`. |

## Solicitudes de Contexto / Declaraciones UNKNOWN
- Ninguna.
```

## Pass / Fail
PASS

## Problem detected (Problema Detectado)
La ejecución inicial de la prueba no agrupaba correctamente los niveles de severidad al evaluar lotes de múltiples sentencias consecutivas.

## Modification made to the skill (Modificación Realizada a la Skill)
Se actualizó la Sección 6.13 en `SKILL.md` para especificar: *"Cuando una sola consulta o lote viola múltiples reglas, el estado general del reporte toma la severidad máxima de cualquier hallazgo detectado en todo el lote."*
