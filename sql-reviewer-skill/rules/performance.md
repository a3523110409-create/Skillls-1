# Performance Rules (`rules/performance.md`)

This module defines rules designed to eliminate database bottlenecks, full-table scans, memory exhaustion, and sub-optimal query execution plans.

---

## PERF-R01: Unbounded Projection (`SELECT *`)

### Rule Definition
`IF` statement is `SELECT` `AND` projects columns using wildcard character `*` or `table_alias.*`, `THEN` flag as **HIGH** severity violation.

> **Justification:** `SELECT *` transfers unneeded columns over the network, increases memory buffer consumption on database and application servers, prevents index-only scan optimizations (covering indexes), and risks breaking application layers when schema migrations add or reorder columns.

### Code Examples

#### Incorrect (FAIL)
```sql
SELECT * FROM TA_ORDERS WHERE FDORDER_DATE >= '2026-01-01';
```

#### Correct (PASS)
```sql
SELECT FNORDER_ID, FNUSER_ID, FNTOTAL_AMOUNT, FDORDER_DATE 
FROM TA_ORDERS 
WHERE FDORDER_DATE >= '2026-01-01';
```

---

## PERF-R06: Mass Query Pagination Guard (`LIMIT` Enforcement)

### Rule Definition
`IF` statement is `SELECT` targeting transactional tables without a `LIMIT` / `TOP` / `FETCH FIRST` clause `OR` contains a cosmetic limit (`LIMIT >= 1000000`), `THEN` flag as **HIGH** severity (`CRITICAL` if `LIMIT >= 1000000000`).

> **Justification:** Unbounded queries or cosmetic high limits (e.g. `LIMIT 1000000000`) cause massive result sets to be fetched into application memory, leading to heap exhaustion (OOM), high CPU locks, and disk paging on the database instance.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Missing LIMIT clause
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS ORDER BY FDCREATED_AT DESC;

-- Cosmetic LIMIT evasion
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS LIMIT 1000000000;
```

#### Correct (PASS)
```sql
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS ORDER BY FDCREATED_AT DESC LIMIT 100;
```

---

## PERF-R09: Missing Index Coverage on Join and Filter Predicates

### Rule Definition
`IF` statement joins tables or filters via `WHERE` / `GROUP BY` on columns without supporting B-Tree / Hash indexes verified in schema metadata, `THEN` flag as **HIGH** severity (if missing index is confirmed) or **INFO** / `UNKNOWN` (if schema metadata is absent).

> **Justification:** Querying unindexed columns forces the query optimizer to perform a Sequential Full Table Scan ($O(N)$), causing severe Disk I/O bottlenecks and elevated table locking on concurrent workloads.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Unindexed search predicate (assuming FCEMAIL lacks an index)
SELECT FNUSER_ID, FCNAME FROM TA_USERS WHERE FCEMAIL = 'user@example.com';
```

#### Correct (PASS)
```sql
-- Predicate on indexed Primary Key / Indexed Column
SELECT FNUSER_ID, FCNAME FROM TA_USERS WHERE FNUSER_ID = 502;
```

---

## PERF-R10: Non-SARGable Predicates and Correlated Subqueries

### Rule Definition
`IF` `WHERE` predicate wraps an indexed column in a scalar function (e.g., `YEAR()`, `LOWER()`, `SUBSTRING()`, arithmetic operations) `OR` `SELECT` projection uses correlated subqueries that evaluate per row, `THEN` flag as **HIGH** severity violation.

> **Justification:** Wrapping columns in scalar functions renders the predicate non-SARGable (Search Argument Able), preventing the database optimizer from walking the index tree and forcing a full scan of all rows. Correlated subqueries introduce $O(N)$ complexity by re-executing the subquery for every outer row.

### Code Examples

#### Incorrect (FAIL)
```sql
-- Function wrapping indexed column (Non-SARGable)
SELECT FNORDER_ID FROM TA_ORDERS WHERE YEAR(FDORDER_DATE) = 2026;

-- Correlated subquery in SELECT projection
SELECT u.FNUSER_ID, 
       (SELECT COUNT(*) FROM TA_ORDERS o WHERE o.FNUSER_ID = u.FNUSER_ID) AS total_orders
FROM TA_USERS u;
```

#### Correct (PASS)
```sql
-- Range filter retaining raw column (SARGable)
SELECT FNORDER_ID FROM TA_ORDERS 
WHERE FDORDER_DATE >= '2026-01-01' AND FDORDER_DATE < '2027-01-01';

-- Explicit JOIN aggregation
SELECT u.FNUSER_ID, COUNT(o.FNORDER_ID) AS total_orders
FROM TA_USERS u
LEFT JOIN TA_ORDERS o ON u.FNUSER_ID = o.FNUSER_ID
GROUP BY u.FNUSER_ID;
```

---

## PERF-R12: [REGLA PROPIA] Implicit Data Type Coercion in Predicates

### Rule Definition
`IF` join predicate or `WHERE` clause compares a column against a literal or column of a mismatched data type (e.g., string column compared to integer literal `FCCODE = 123` or numeric column compared to string `'500'`), `THEN` flag as **HIGH** severity violation.

> **Justification:** When data types mismatch, SQL engines dynamically cast column data row-by-row during execution. This dynamic type coercion neutralizes existing index trees and consumes substantial CPU cycles.

### Code Examples

#### Incorrect (FAIL)
```sql
-- FCACCOUNT_NUMBER is VARCHAR(50), but filtered with Integer literal
SELECT FNUSER_ID FROM TA_ACCOUNTS WHERE FCACCOUNT_NUMBER = 987654321;
```

#### Correct (PASS)
```sql
-- Filtered with matching string literal type
SELECT FNUSER_ID FROM TA_ACCOUNTS WHERE FCACCOUNT_NUMBER = '987654321';
```
