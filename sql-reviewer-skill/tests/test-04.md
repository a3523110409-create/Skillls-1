# Pruebas Test 04: Evaluación de Información Insuficiente

## Input (Entrada)
```sql
UPDATE TA_USUARIOS 
SET FCESTADO = 'INACTIVO' 
WHERE FDU LTIMO_ACCESO < '2025-01-01';
```

*(Nota: Los metadatos del esquema, la cobertura de índices, las configuraciones de triggers y las políticas de negocio de borrado lógico NO fueron proporcionados deliberadamente en el prompt).*

## Expected behavior (Comportamiento Esperado)
La consulta contiene un `UPDATE` sintácticamente válido con un filtro `WHERE`. Sin embargo:
1. La cobertura de índice en `FDU LTIMO_ACCESO` no se puede verificar sin las definiciones del esquema (`R09`).
2. Las políticas de borrado lógico / ejecución de triggers en `TA_USUARIOS` están ausentes (`R11`).
3. El conteo total de filas afectadas es desconocido (riesgo potencial de actualización masiva según el volumen).

La skill **NO DEBE** inventar contexto ni alucinar la presencia/ausencia de índices. Debe reportar `Overall Result: INSUFFICIENT CONTEXT`, clasificar los hallazgos como `Severidad: INFO` con estado `UNKNOWN` y solicitar al usuario los detalles del esquema.

## Actual behavior (Comportamiento Real)
```markdown
# Reporte de Revisión de Código SQL

## Resumen
- **Resultado General**: INSUFFICIENT CONTEXT
- **Severidad Máxima**: INFO
- **Total de Hallazgos**: 2

## Detalle de Hallazgos

| Línea | Regla Violada | Severidad | Explicación Técnica | Remediación Recomendada |
| :--- | :--- | :--- | :--- | :--- |
| Línea 3 | R09: Verificación de Índice Faltante | INFO | [STATUS: UNKNOWN] No se puede determinar si `FDU LTIMO_ACCESO` está cubierta por un índice B-Tree debido a la falta de metadatos del esquema. Si no está indexada, este UPDATE provocará un escaneo completo de la tabla. | Proporcionar `SHOW INDEX FROM TA_USUARIOS` o el DDL del esquema para confirmar la cobertura de índices. |
| Línea 1 | R11: Contexto de Auditoría y Borrado Lógico | INFO | [STATUS: UNKNOWN] No se puede verificar si `TA_USUARIOS` tiene triggers de UPDATE activos o columnas de auditoría (`FDFECHA_ACTUALIZACION`, `FCACTUALIZADO_POR`) requeridas por la política empresarial. | Proporcionar la lista de triggers o columnas del esquema para verificar el cumplimiento de auditoría. |

## Solicitudes de Contexto / Declaraciones UNKNOWN
- Metadatos de Índices Faltantes: Proporcionar definiciones DDL/índices para la tabla `TA_USUARIOS`.
- Volumen de Datos Faltante: Especificar el recuento estimado de filas para `TA_USUARIOS` para evaluar el impacto en la duración de bloqueos.
```

## Pass / Fail
PASS

## Problem detected (Problema Detectado)
En las primeras pruebas, la skill asumía que `FDU LTIMO_ACCESO` no tenía índice y activaba una violación de severidad `HIGH`. Esto violaba la Restricción Dura 3 (Prohibido inventar contexto).

## Modification made to the skill (Modificación Realizada a la Skill)
Se agregó la Sección 11 (`Failure Handling`, punto 4) y la Sección 3 en `SKILL.md`, instruyendo estrictamente a la skill a declarar las reglas deficientes de contexto como `INFO / UNKNOWN` y solicitar entrada al usuario en lugar de alucinar hallazgos.
