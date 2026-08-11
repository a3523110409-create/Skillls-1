# Test 03: Edge Case Evaluation

## Input
```sql
SELECT FNUSER_ID, FCNAME 
FROM TA_USERS 
WHERE LOWER(FCEMAIL) = 'admin@company.com' 
LIMIT 10;
```

## Expected behavior
The query superficially looks valid (explicit projection, selective filter, `LIMIT 10`). However, wrapping `FCEMAIL` inside `LOWER()` makes the filter Non-SARGable. The skill must detect `R10` (`HIGH` severity).

## Actual behavior
```markdown
# SQL Code Review Report

## Summary
- **Overall Result**: ACTION REQUIRED
- **Highest Severity**: HIGH
- **Total Findings**: 1

## Findings Detail

| Line | Rule Violated | Severity | Technical Explanation | Recommended Remediation |
| :--- | :--- | :--- | :--- | :--- |
| Line 3 | R10: Non-SARGable Filter | HIGH | Function `LOWER(FCEMAIL)` wraps an indexed column in the filter predicate. This prevents B-Tree index scans and forces a full table scan. | Remove scalar function from column side, or use a functional/expression index: `WHERE FCEMAIL = 'admin@company.com'`. |

## Context Requests / UNKNOWN Declarations
- None.
```

## Pass / Fail
PASS

## Problem detected
Regex-only evaluation passed the query because `WHERE` and `LIMIT` were present. Semantic AST/intent evaluation was required to detect scalar function wrapping.

## Modification made to the skill
Refined rule `R10` in `SKILL.md` and `rules/performance.md` to explicitly parse function calls wrapping predicate identifiers on the LHS of `WHERE` operators.
