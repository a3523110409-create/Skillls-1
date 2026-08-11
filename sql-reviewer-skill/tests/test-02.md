# Test 02: Evident Errors Evaluation

## Input
```sql
SELECT * FROM TA_USERS WHERE FDDELETED_AT = NULL;
DELETE FROM TA_ORDERS;
```

## Expected behavior
The skill detects multiple blatant violations:
1. `R01`: Projection wildcard `SELECT *` (`HIGH`).
2. `R07`: Invalid comparison `= NULL` (`MEDIUM`).
3. `R02` & `R06`: Unbounded `DELETE FROM TA_ORDERS` without `WHERE` (`CRITICAL`).
Overall status reported as `ACTION REQUIRED` with highest severity `CRITICAL`.

## Actual behavior
```markdown
# SQL Code Review Report

## Summary
- **Overall Result**: ACTION REQUIRED
- **Highest Severity**: CRITICAL
- **Total Findings**: 3

## Findings Detail

| Line | Rule Violated | Severity | Technical Explanation | Recommended Remediation |
| :--- | :--- | :--- | :--- | :--- |
| Line 1 | R01: Selective Projection | HIGH | Query uses `SELECT *`, fetching unnecessary columns and increasing network/memory load. | Explicitly specify required columns: `SELECT FNUSER_ID, FCEMAIL...`. |
| Line 1 | R07: NULL Comparison | MEDIUM | Predicate compares `FDDELETED_AT = NULL`. In ANSI SQL 3VL, `= NULL` evaluates to UNKNOWN, returning 0 rows. | Change operator to `IS NULL`: `WHERE FDDELETED_AT IS NULL`. |
| Line 2 | R02: Safe DELETE Filter | CRITICAL | Statement `DELETE FROM TA_ORDERS` lacks a `WHERE` clause, which will cause complete data erasure of TA_ORDERS. | Add selective `WHERE` clause: `WHERE FNORDER_ID = :orderId`. |

## Context Requests / UNKNOWN Declarations
- None.
```

## Pass / Fail
PASS

## Problem detected
Initial test run did not group severity levels properly when evaluating multi-statement inputs in sequence.

## Modification made to the skill
Updated Section 6.13 in `SKILL.md` to specify: *"When a single query or batch violates multiple rules, the overall report status takes the maximum severity of any individual finding triggered across the entire batch."*
