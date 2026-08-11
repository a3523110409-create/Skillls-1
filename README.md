# Skill Revisor de SQL (`sql-reviewer-skill`)

Una skill determinista y de nivel producción para análisis estático, auditoría de seguridad, optimización de rendimiento y aplicación de convenciones en consultas SQL.

Diseñada para una integración fluida en pipelines de revisión de código, asistentes de IA y flujos de trabajo de CI/CD automatizados.

---

## 📌 Estructura del Repositorio

```
sql-reviewer-skill/
|-- SKILL.md                  # Definición Principal de la Skill y Reglas Deterministas
|-- README.md                 # Visión General del Proyecto y Documentación de Uso
|-- rules/                    # Definición Detallada de Reglas y Ejemplos de Código
|   |-- security.md           # Reglas de Seguridad y Mitigación de Inyección SQL (SEC-R02, R04, R11)
|   |-- performance.md        # Reglas de Optimización de Latencia, Índices y Memoria (PERF-R01, R06, R09, R10, R12)
|   `-- conventions.md        # Reglas de Estándares de Nombres y Manejo de Lógica 3VL (CONV-R05, R07, R08)
|-- examples/                 # Archivos de Referencia de Scripts SQL
|   |-- valid.sql             # Consultas SQL válidas (0 falsos positivos)
|   |-- invalid.sql           # Consultas con fallos explícitos violando R01-R12
|   `-- edge-cases.sql        # Consultas de evasión cosmética y casos de borde
`-- tests/                    # Suites de Prueba y Verificación
    |-- test-01.md            # Test 01: Evaluación de Camino Feliz (Happy Path)
    |-- test-02.md            # Test 02: Evaluación de Errores Evidentes
    |-- test-03.md            # Test 03: Evaluación de Casos de Borde / No SARGables
    |-- test-04.md            # Test 04: Evaluación de Información Insuficiente / Contexto UNKNOWN
    `-- test-05.md            # Test 05: Evaluación de Red Team / Evasión Adversarial
```

---

## 🚀 Cómo Usar la Skill

### 1. En Entornos de Agentes de IA (Google Antigravity, Claude, ChatGPT, Cursor)
Copia el archivo [`SKILL.md`](sql-reviewer-skill/SKILL.md) en el directorio `.gemini/skills/sql-reviewer/SKILL.md` o `.cursor/rules/` de tu proyecto.

### 2. Prompt de Ejecución Manual
Al realizar una consulta a un asistente de IA cargado con esta skill:
```text
Revisa la siguiente sentencia SQL utilizando las reglas de la skill sql-reviewer:

[INSERTA TU CONSULTA SQL AQUÍ]
```

### 3. Integración en Pre-commit Hooks de CI/CD
Invoca el procedimiento determinista definido en `SKILL.md` para evaluar archivos SQL contra las reglas `R01` a `R12` antes de fusionar los pull requests.

---

## 🛡️ Resumen de Reglas Propias del Equipo (`[REGLA PROPIA]`)

Además de los 10 puntos obligatorios de revisión SQL, este repositorio incluye **2 reglas empresariales propias**:

1. **R11: Integridad Referencial en Cascade de FK y Borrado Lógico (`[REGLA PROPIA]`)**
   - **Disparador**: `IF` una consulta intenta un `DELETE` físico en una tabla con columna de borrado lógico (`fdes_eliminado`, `fdeliminado_at`) `OR` ejecuta borrados de restricciones de clave foránea sin cascada.
   - **Severidad**: `HIGH` / `CRITICAL`
   - **Justificación**: Previene registros huérfanos en tablas hijas y protege los registros de auditoría de borrado lógico contra su eliminación permanente.

2. **R12: Coerción Implícita de Tipos de Datos en Predicados (`[REGLA PROPIA]`)**
   - **Disparador**: `IF` un predicado de join o cláusula `WHERE` compara tipos de datos no coincidentes (ej. `FCCUENTA_NUMERO = 12345` o `FNNUMERO_ID = '123'`).
   - **Severidad**: `HIGH`
   - **Justificación**: El casteo dinámico de tipos fila por fila invalida los índices de la base de datos y consume ciclos excesivos de CPU.

---

## 🧪 Resumen de Resultados de Pruebas y Red Team

Las **5 suites de prueba de verificación** pasaron con una **tasa de éxito del 100%**:

| Suite de Prueba | Tipo de Prueba | Estado | Resumen / Hallazgos Clave |
| :--- | :--- | :--- | :--- |
| **Test 01** | Camino Feliz (Happy Path) | `PASSED` | Se verificó que las consultas limpias generan cero falsos positivos. |
| **Test 02** | Errores Evidentes | `PASSED` | Detectó correctamente `DELETE` sin `WHERE`, `SELECT *` y `= NULL`. |
| **Test 03** | Casos de Borde | `PASSED` | Detectó la función no SARGable `LOWER()` envolviendo la columna indexada. |
| **Test 04** | Información Insuficiente | `PASSED` | Marcó el contexto de esquema faltante como `INFO / UNKNOWN` sin alucinar suposiciones. |
| **Test 05** | Red Team / Adversarial | `PASSED` | Bloqueó con éxito 5 intentos de evasión (`1=1`, `LIMIT 1000000000`, `LIKE '%'`, `OR` tautológico y límite de 5M). |

### Mejoras Clave Realizadas Tras la Simulación de Red Team:
- Se mejoró `R02` pasando de coincidencia de texto literal `1=1` a **evaluación semántica de tautologías** (`IS NOT NULL OR IS NULL`, `'x'='x'`).
- Se mejoró `R06` para clasificar límites $\ge 1,000,000$ como **riesgos cosméticos de evasión de memoria**.
- Se reforzó `Failure Handling` para asegurar que el contexto de esquema ausente active el estado `INFO / UNKNOWN` en lugar de alucinar el estado del índice.
