# Pruebas Test 05: Evaluación Adversarial / Simulación de Red Team

## Input (Entrada)
```sql
-- Entrada 1 (Red Team Profesor 1): Evasión por cláusula WHERE cosmética
DELETE FROM TA_USUARIOS WHERE 1 = 1;

-- Entrada 2 (Red Team Profesor 2): Evasión por LIMIT cosmético + SELECT *
SELECT * FROM TA_USUARIOS LIMIT 1000000000;

-- Entrada 3 (Red Team Profesor 3): Evasión por cláusula WHERE comodín
UPDATE TA_USUARIOS SET FCROL = 'ADMINISTRA' WHERE FCCORREO LIKE '%';

-- Entrada 4 (Adversarial Propia 1): Filtro de evasión tautológico con OR
DELETE FROM TA_USUARIOS WHERE FCCORREO IS NOT NULL OR FCCORREO IS NULL;

-- Entrada 5 (Adversarial Propia 2): Evasión por límite numérico elevado
SELECT FNUSUARIO_ID, FCCORREO FROM TA_USUARIOS WHERE 'x' = 'x' ORDER BY 1 LIMIT 5000000;
```

## Expected behavior (Comportamiento Esperado)
La skill NO debe dejarse engañar por la presencia superficial de cláusulas (`WHERE`, `LIMIT`, `LIKE`).
- Entrada 1: Marcar como `CRITICAL` bajo `R02` (`1=1` cosmético es equivalente a un DELETE incondicional).
- Entrada 2: Marcar como `CRITICAL` bajo `R06` (`LIMIT >= 1 Billón` es cosmético) Y `HIGH` bajo `R01` (`SELECT *`).
- Entrada 3: Marcar como `CRITICAL` bajo `R02` (Comodín `LIKE '%'` coincide con todas las filas, actualización masiva no intencionada).
- Entrada 4: Marcar como `CRITICAL` bajo `R02` (Tautología `IS NOT NULL OR IS NULL` selecciona el 100% de las filas).
- Entrada 5: Marcar como `CRITICAL` bajo `R06` (Límite 5 Millones supera el umbral seguro de memoria) Y `CRITICAL` bajo `R02` (`'x'='x'`).

Resultado general reportado como `ACTION REQUIRED` con severidad máxima `CRITICAL`.

## Actual behavior (Comportamiento Real)
```markdown
# Reporte de Revisión de Código SQL

## Resumen
- **Resultado General**: ACTION REQUIRED
- **Severidad Máxima**: CRITICAL
- **Total de Hallazgos**: 6

## Detalle de Hallazgos

| Línea | Regla Violada | Severidad | Explicación Técnica | Remediación Recomendada |
| :--- | :--- | :--- | :--- | :--- |
| Línea 2 | R02: Filtro DELETE Seguro | CRITICAL | La sentencia utiliza el filtro cosmético `WHERE 1 = 1` que se evalúa como TRUE para todas las filas, resultando en el vaciado completo de TA_USUARIOS. | Reemplazar `1=1` con un límite explícito por clave primaria: `WHERE FNUSUARIO_ID = :id`. |
| Línea 5 | R01: Proyección Selectiva | HIGH | La sentencia utiliza el comodín de proyección `SELECT *`. | Reemplazar `*` con la lista explícita de columnas. |
| Línea 5 | R06: Límite en Consulta Masiva | CRITICAL | El parámetro `LIMIT 1000000000` (1 Billón) es un límite cosmético que no ofrece protección contra caídas OutOfMemory. | Reducir el límite a un rango realista de paginación (`LIMIT 100` - `LIMIT 1000`). |
| Línea 8 | R02: Filtro UPDATE Seguro | CRITICAL | El filtro `WHERE FCCORREO LIKE '%'` coincide con el 100% de los registros no nulos, causando una actualización masiva no intencionada de todos los roles a ADMINISTRA. | Especificar el correo o el ID del usuario objetivo explícitamente. |
| Línea 11| R02: Filtro DELETE Seguro | CRITICAL | El filtro tautológico `WHERE FCCORREO IS NOT NULL OR FCCORREO IS NULL` se evalúa como TRUE para cada fila, borrando todos los registros. | Remover la tautología y pasar un identificador de entidad explícito. |
| Línea 14| R06: Límite en Consulta Masiva | CRITICAL | El parámetro `LIMIT 5000000` excede el umbral máximo de seguridad de memoria (1,000,000). | Implementar paginación basada en cursor o reducir el límite a <= 1,000. |

## Solicitudes de Contexto / Declaraciones UNKNOWN
- Ninguna.
```

## Pass / Fail
PASS

## Problem detected (Problema Detectado)
El borrador inicial de la skill solo verificaba coincidencia literal de cadenas `1=1`. Las entradas adversariales de prueba (`IS NOT NULL OR IS NULL` y `'x'='x'`) evadían los comparadores iniciales.

## Modification made to the skill (Modificación Realizada a la Skill)
Se actualizaron la Sección 6 (`R02` y `R06`) en `SKILL.md` y `rules/security.md` para definir la evaluación semántica de tautologías:
- *Condición*: `IF la cláusula WHERE se evalúa como incondicionalmente TRUE (ej. 1=1, 'a'='a', IS NOT NULL OR IS NULL, LIKE '%'), THEN marcar como CRITICAL.`
- *Condición*: `IF LIMIT es mayor o igual a 1,000,000, THEN marcar como límite cosmético de severidad HIGH/CRITICAL.`
