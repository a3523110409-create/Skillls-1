# Security Rules (`rules/security.md`)

This module defines deterministic and intent-focused security rules for reviewing SQL queries. Security findings take top priority in code reviews.

---

## SEC-R02: Unbounded or Cosmetic Filtering on `UPDATE` / `DELETE`

### Rule Definition
`IF` statement is `UPDATE` or `DELETE` `AND` (`WHERE` clause is missing `OR` `WHERE` clause evaluates to unconditional true such as `1=1`, `0=0`, `'a'='a'`, `TRUE`, or wildcard pattern `FCEMAIL LIKE '%'`), `THEN` flag as **CRITICAL** severity violation.

> **Justification:** Executing `DELETE` or `UPDATE` statements without a selective `WHERE` clause results in immediate full-table modification or data loss. Cosmetic filters like `WHERE 1=1` or `WHERE FCEMAIL LIKE '%'` are deliberate pattern evasion techniques that bypass naive regex checks while causing identical catastrophic loss.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Missing WHERE clause
DELETE FROM TA_USERS;

-- Cosmetic filter (Always True)
DELETE FROM TA_USERS WHERE 1 = 1;

-- Wildcard filter selecting 100% of rows
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';
```

#### Correct (PASS)
```sql
-- Specific primary key filtering
DELETE FROM TA_USERS WHERE FNUSER_ID = 4821;

-- Parametric bounded update
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FNUSER_ID = :userId AND FCSTATUS = 'ACTIVE';
```

---

## SEC-R04: Dynamic SQL String Concatenation (SQL Injection Risk)

### Rule Definition
`IF` statement constructs SQL queries via string concatenation (`+`, `||`, `CONCAT()`) using un-sanitized external variables or input strings, `THEN` flag as **CRITICAL** severity violation.

> **Justification:** String concatenation allows attackers to inject malicious SQL fragments, bypassing authentication, dumping database contents, or executing administrative commands. All variable inputs must use prepared statements with bind parameters.

### Code Examples

#### Incorrect (FAIL)
```sql
-- String concatenation with input variable
SELECT * FROM TA_USERS WHERE FCEMAIL = '' + user_input + '';

-- CONCAT function with dynamic variable
SELECT FCNAME, FCEMAIL FROM TA_USERS WHERE FCROLE = CONCAT('USER_', input_role);
```

#### Correct (PASS)
```sql
-- Parameterized prepared statement
SELECT FCUSER_ID, FCNAME, FCEMAIL FROM TA_USERS WHERE FCEMAIL = :email;

-- Positional bound parameter
SELECT FCNAME, FCEMAIL FROM TA_USERS WHERE FCROLE = $1;
```

---

## SEC-R11: [REGLA PROPIA] Unsafe Destructive Schema Changes and Soft-Delete Bypass

### Rule Definition
`IF` statement executes `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`, `ALTER TABLE ... DROP COLUMN` `OR` hard `DELETE` on tables configured for soft-deletion (`is_deleted` or `fd_deleted_at` present), `THEN` flag as **CRITICAL** (for DDL) or **HIGH** (for hard DELETE).

> **Justification:** Destructive DDL bypasses transactional rollbacks in many engines and permanently removes structure/data. Hard `DELETE` on soft-delete entity tables corrupts audit trails and historic reporting analytics.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Direct table truncate
TRUNCATE TABLE TA_TRANSACTIONS;

-- Hard delete on soft-delete audited table
DELETE FROM TA_USERS WHERE FNUSER_ID = 102;
```

#### Correct (PASS)
```sql
-- Soft delete update pattern
UPDATE TA_USERS SET FDIS_DELETED = 1, FDDELETED_AT = CURRENT_TIMESTAMP WHERE FNUSER_ID = 102;
```
