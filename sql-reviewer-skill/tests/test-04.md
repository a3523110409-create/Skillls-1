# Test 04: Insufficient Information Evaluation

## Input
```sql
UPDATE TA_USERS 
SET FCSTATUS = 'INACTIVE' 
WHERE FDLAST_LOGIN < '2025-01-01';
```

*(Note: Schema metadata, index coverage definitions, trigger configurations, and soft-delete business policies were deliberately NOT provided with this query prompt).*

## Expected behavior
The query contains a syntactically valid `UPDATE` with a `WHERE` filter. However:
1. Index coverage on `FDLAST_LOGIN` cannot be verified without schema index definitions (`R09`).
2. Soft-delete / trigger execution policies on `TA_USERS` are missing (`R11`).
3. Total affected row count is unknown (potential mass update risk depending on table volume).

The skill **MUST NOT** invent context or hallucinate index presence/absence. It must report `Overall Result: INSUFFICIENT CONTEXT`, classify findings as `Severity: INFO` with status `UNKNOWN`, and prompt the user for necessary schema details.

## Actual behavior
```markdown
# SQL Code Review Report

## Summary
- **Overall Result**: INSUFFICIENT CONTEXT
- **Highest Severity**: INFO
- **Total Findings**: 2

## Findings Detail

| Line | Rule Violated | Severity | Technical Explanation | Recommended Remediation |
| :--- | :--- | :--- | :--- | :--- |
| Line 3 | R09: Missing Index Verification | INFO | [STATUS: UNKNOWN] Cannot determine if `FDLAST_LOGIN` is covered by a B-Tree index due to missing schema index metadata. If unindexed, this UPDATE will trigger a full table scan. | Provide `SHOW INDEX FROM TA_USERS` or DDL schema to confirm index coverage. |
| Line 1 | R11: Audit & Soft Delete Context | INFO | [STATUS: UNKNOWN] Cannot verify if `TA_USERS` has active UPDATE triggers or auditing columns (`FDUPDATED_AT`, `FCUPDATED_BY`) required by enterprise policy. | Provide schema triggers or column list to verify auditing compliance. |

## Context Requests / UNKNOWN Declarations
- Missing Index Metadata: Please provide DDL/index definitions for table `TA_USERS`.
- Missing Table Volume Data: Please specify estimated total row count for `TA_USERS` to evaluate lock duration impact.
```

## Pass / Fail
PASS

## Problem detected
In early testing, the skill assumed `FDLAST_LOGIN` was unindexed and triggered a `HIGH` severity violation. This violated Hard Constraint 3 (Prohibido inventar contexto).

## Modification made to the skill
Added Section 11 (`Failure Handling`, point 4) and Section 3 (`hard constraint on missing context`) in `SKILL.md`, strictly instructing the skill to declare context-deficient rules as `INFO / UNKNOWN` and request user input rather than hallucinating findings.
