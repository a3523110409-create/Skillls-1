# Pruebas Test 03: Evaluación de Casos de Borde (Edge Cases)

## Input (Entrada)
```sql
SELECT FNUSUARIO_ID, FCNOMBRE 
FROM TA_USUARIOS 
WHERE LOWER(FCCORREO) = 'admin@empresa.com' 
LIMIT 10;
```

## Expected behavior (Comportamiento Esperado)
La consulta parece válida superficialmente (proyección explícita, filtro selectivo, `LIMIT 10`). Sin embargo, envolver `FCCORREO` dentro de `LOWER()` hace que el filtro sea No SARGable. La skill debe detectar `R10` (severidad `HIGH`).

## Actual behavior (Comportamiento Real)
```markdown
# Reporte de Revisión de Código SQL

## Resumen
- **Resultado General**: ACTION REQUIRED
- **Severidad Máxima**: HIGH
- **Total de Hallazgos**: 1

## Detalle de Hallazgos

| Línea | Regla Violada | Severidad | Explicación Técnica | Remediación Recomendada |
| :--- | :--- | :--- | :--- | :--- |
| Línea 3 | R10: Filtro No SARGable | HIGH | La función `LOWER(FCCORREO)` envuelve una columna indexada en el predicado del filtro. Esto previene el escaneo por índice B-Tree y fuerza un escaneo completo de la tabla. | Remover la función escalar del lado de la columna o utilizar un índice funcional/expresión: `WHERE FCCORREO = 'admin@empresa.com'`. |

## Solicitudes de Contexto / Declaraciones UNKNOWN
- Ninguna.
```

## Pass / Fail
PASS

## Problem detected (Problema Detectado)
La evaluación basada únicamente en regex aprobaba la consulta porque `WHERE` y `LIMIT` estaban presentes. Se requirió evaluación semántica/AST para detectar el envoltorio por función escalar.

## Modification made to the skill (Modificación Realizada a la Skill)
Se refinó la regla `R10` en `SKILL.md` y `rules/performance.md` para parsear explícitamente llamadas a funciones escalares que envuelven identificadores en el lado izquierdo (`LHS`) de los operadores del `WHERE`.
