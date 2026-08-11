# Conventions Rules (`rules/conventions.md`)

This module defines maintainability, standards compliance, and logical correctness rules for database schema and query design.

---

## CONV-R05: Naming Conventions and Reserved Words

### Rule Definition
`IF` schema objects (tables, columns, indexes) fail to follow system identifier prefixes (`TA_` for Tables, `FC` for Varchars/Strings, `FN` for Numerics, `FD` for Dates/Timestamps) `OR` utilize SQL reserved keywords (e.g., `USER`, `ORDER`, `GROUP`, `KEY`), special characters, camelCase, or spaces, `THEN` flag as **LOW** severity violation.

> **Justification:** Standardized naming prefixes immediately convey variable data types to backend engineers, prevent syntax errors caused by unquoted reserved keyword collisions, and ensure cross-platform consistency.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Unquoted reserved word 'USER' and camelCase column name
CREATE TABLE users (
    userId INT,
    user = VARCHAR(100)
);
```

#### Correct (PASS)
```sql
CREATE TABLE TA_USERS (
    FNUSER_ID INT PRIMARY KEY,
    FCUSER_NAME VARCHAR(100) NOT NULL
);
```

---

## CONV-R07: Three-Valued Logic NULL Comparison Syntax

### Rule Definition
`IF` filtering predicate compares `NULL` using equality or inequality operators (`= NULL`, `<> NULL`, `!= NULL`), `THEN` flag as **MEDIUM** severity violation.

> **Justification:** Under ANSI SQL Three-Valued Logic (3VL), `NULL = NULL` and `val = NULL` evaluate to `UNKNOWN` rather than `TRUE` or `FALSE`. Using `= NULL` or `!= NULL` in `WHERE` clauses silently results in zero matching rows being returned.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Incorrect equality comparison with NULL
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS WHERE FCDELETED_AT = NULL;

SELECT FNUSER_ID FROM TA_USERS WHERE FCSTATUS != NULL;
```

#### Correct (PASS)
```sql
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS WHERE FCDELETED_AT IS NULL;

SELECT FNUSER_ID FROM TA_USERS WHERE FCSTATUS IS NOT NULL;
```

---

## CONV-R08: Data Type Selection and Entity Representation

### Rule Definition
`IF` primary or foreign key columns use `VARCHAR` without UUID rationale `OR` numeric values are stored as string types `OR` timestamp values are stored as unformatted text, `THEN` flag as **MEDIUM** severity violation.

> **Justification:** Misaligned data types increase disk storage footprints, degrade CPU cache effectiveness during join operations, and prevent native database date/time index math optimization.

### Code Examples

#### Incorrect (FAIL)
```sql
CREATE TABLE TA_PAYMENTS (
    FCPAYMENT_ID VARCHAR(50) PRIMARY KEY, -- Integer sequence stored as VARCHAR
    FCRECEIPT_DATE VARCHAR(30)           -- Timestamp stored as string
);
```

#### Correct (PASS)
```sql
CREATE TABLE TA_PAYMENTS (
    FNPAYMENT_ID INT AUTO_INCREMENT PRIMARY KEY,
    FDPAYMENT_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
