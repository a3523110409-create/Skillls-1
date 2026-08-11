# SQL Reviewer

## Purpose
The `sql-reviewer` skill provides a deterministic, rigorous, and automated code review framework for SQL statements intended for production environments. It enforces industry-standard best practices across database security, performance, data integrity, and naming conventions by evaluating queries against explicit conditional rules (`IF ... THEN ...`). It minimizes false positives and eliminates hallucinated context by declaring ambiguous or context-deficient scenarios as `INFO` or `UNKNOWN`.

## When to activate
Activate this skill in any of the following scenarios:
1. User requests a SQL code review, audit, security scan, or query performance analysis.
2. User provides a `.sql` file, SQL snippet, migration script, or DDL/DML statement asking for feedback or optimization.
3. User asks to verify compliance of SQL code against database best practices prior to pull request approval or deployment.
4. Automated pre-commit hooks or CI/CD workflow triggers require structured SQL evaluation.

## When NOT to activate
The `sql-reviewer` skill MUST explicitly refrain from activating in the following scenarios:
1. **Non-SQL Input**: Input consists of non-SQL code (e.g., Python ORM code like SQLAlchemy/Prisma, bash scripts, JSON, NoSQL queries like MongoDB aggregation pipelines) unless raw SQL strings are explicitly isolated for review.
2. **Unsupported Engine DDL**: Input contains proprietary vendor DDL or extensions for engines outside supported ANSI SQL / PostgreSQL / MySQL / Oracle standards (e.g., PL/SQL package bodies, T-SQL extended stored procedure binaries) without standard query syntax context.
3. **Incomplete / Syntactically Truncated Snippets**: Input contains arbitrary text fragments, partial clauses (e.g., just `LEFT JOIN table_b ON`), or pseudo-code without full statement context.
4. **Already Approved PRs without Intent Context**: Input is a historical diff or approved database log presented solely for documentation or archival without intent to modify or audit code logic.

## Inputs
- **Primary Input**: Raw SQL script, migration file, DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`), or DDL (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`).
- **Optional Context**: Target Database Engine (PostgreSQL, MySQL, Oracle, SQL Server), Schema definitions/DDL, index definitions, table row counts, and intent metadata.

## Procedure
Execute the following deterministic evaluation algorithm for every SQL review request:

1. **Input Parsing & Validation**:
   - Parse the input string into discrete SQL statements.
   - Verify syntactical validity. If syntax errors exist, halt evaluation and trigger `Failure Handling` (Section 11).
2. **Statement Classification**:
   - Classify each statement by category: DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`), DDL (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`), or Transaction Management (`COMMIT`, `ROLLBACK`).
3. **Context Availability Assessment**:
   - Check if necessary external metadata (schema indexes, table size, soft-delete configuration) is present. If missing, mark context-dependent rules as `UNKNOWN` or `INFO` rather than assuming compliance/non-compliance.
4. **Rule Evaluation (Loop per statement)**:
   - Run each statement against the 12 explicit rules defined in Section 6 (`R01` through `R12`).
   - Evaluate both superficial pattern matches AND semantic intent (e.g., detect cosmetic `WHERE 1=1` or cosmetic `LIMIT 1000000000`).
5. **Severity Assignment & Conflict Resolution**:
   - Assign severity levels (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`) based strictly on objective criteria defined in Section 7.
   - Apply conflict resolution priority (Security > Data Integrity > Performance > Conventions) defined in Section 6.13.
6. **Output Formatting**:
   - Generate structured Markdown report adhering strictly to the `Expected output` template in Section 8.

## Rules

### R01: Selective Column Retrieval (No `SELECT *`)
- **Condition**: `IF` statement is `SELECT` `AND` uses wildcards (`*` or `table.*`) in column projection.
- **Action**: `THEN` flag as `HIGH` severity violation. Require explicit column listing.
- **Justification**: Avoids unnecessary I/O, memory bloat, network latency, and breaking API contracts when schema changes occur.

### R02: Safe `UPDATE` / `DELETE` Execution (No Unbounded or Cosmetic Filtering)
- **Condition**: `IF` statement is `UPDATE` or `DELETE` `AND` (`WHERE` clause is missing `OR` `WHERE` clause evaluates to unconditional true such as `1=1`, `0=0`, `'a'='a'`, or `FCEMAIL LIKE '%')`.
- **Action**: `THEN` flag as `CRITICAL` severity violation. Block execution immediately.
- **Justification**: Prevents catastrophic bulk data erasure or unintended full-table updates. Cosmetic filters designed to bypass simple checks are classified as intent-evasion security vulnerabilities.

### R03: Destructive DDL Guardrails
- **Condition**: `IF` statement contains `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`, or `ALTER TABLE ... DROP COLUMN`.
- **Action**: `THEN` flag as `CRITICAL` severity violation. Require explicit migration approval tag and backup verification.
- **Justification**: Permanent, non-transactional or unrecoverable data loss operations must require high-friction manual sign-off.

### R04: Dynamic SQL Injection Mitigation
- **Condition**: `IF` SQL statement contains string concatenation (e.g., `+`, `||`, `CONCAT()`) involving external user input variables or un-parameterized dynamic query strings.
- **Action**: `THEN` flag as `CRITICAL` severity violation. Require parameterized queries (`?`, `:param`, `$1`).
- **Justification**: Prevents remote code execution, database takeover, and unauthorized access via SQL injection attacks.

### R05: Database Naming Conventions
- **Condition**: `IF` table, column, or index identifiers do not follow prefix conventions (e.g., `TA_` for tables, `FC` for varchar/string fields, `FN` for numeric, `FD` for dates) `OR` use reserved keywords, camelCase, spaces, or special characters.
- **Action**: `THEN` flag as `LOW` severity violation.
- **Justification**: Maintains cross-team readability, prevents engine-specific reserved word collisions, and ensures consistent object naming.

### R06: Mass Query Bound Enforcement (No Missing or Cosmetic `LIMIT`)
- **Condition**: `IF` statement is `SELECT` without an `ORDER BY` and `LIMIT`/`TOP`/`FETCH FIRST` `OR` contains a cosmetic limit (`LIMIT >= 1000000`).
- **Action**: `THEN` flag as `HIGH` severity violation (`CRITICAL` if limit is >= 1,000,000,000).
- **Justification**: Unbounded or fake limits can crash application servers with OutOfMemory errors and exhaust database buffer pools.

### R07: Strict `NULL` Comparison Handling
- **Condition**: `IF` filtering or join predicate compares `NULL` using equality/inequality operators (`= NULL`, `<> NULL`, `!= NULL`).
- **Action**: `THEN` flag as `MEDIUM` severity violation. Require `IS NULL` or `IS NOT NULL`.
- **Justification**: In ANSI SQL, comparisons with `NULL` using `=` or `!=` evaluate to `UNKNOWN` (Three-Valued Logic), causing queries to silently return zero rows.

### R08: Optimal Data Type Selection
- **Condition**: `IF` primary keys or foreign keys use variable-length string types (`VARCHAR`) without UUID rationale `OR` numeric values stored as text `OR` timestamps stored as string.
- **Action**: `THEN` flag as `MEDIUM` severity violation.
- **Justification**: Inefficient data types increase storage footprints, degrade index lookup speed, and disable engine page cache optimizations.

### R09: Missing Index Detection on Join & Filter Predicates
- **Condition**: `IF` query performs `JOIN`, `WHERE`, or `GROUP BY` on columns without confirmed index coverage in schema context.
- **Action**: `THEN` flag as `HIGH` severity violation if index absence is confirmed, `OR` flag as `INFO` with `UNKNOWN` status if schema context is missing.
- **Justification**: Unindexed predicate columns force expensive sequential full-table scans, increasing Disk I/O and query latency exponentially.

### R10: Performance Anti-Pattern Detection (Non-SARGable & Correlated Subqueries)
- **Condition**: `IF` `WHERE` clause applies scalar functions on indexed columns (e.g., `WHERE YEAR(d_date) = 2026` or `LOWER(fc_email) = '...'`) `OR` uses correlated subqueries in `SELECT` projections (`N+1` pattern).
- **Action**: `THEN` flag as `HIGH` severity violation.
- **Justification**: Functions on predicate columns invalidate index B-Trees (Non-SARGable), forcing full-table scans. Correlated subqueries execute per row, resulting in $O(N)$ execution complexity.

### R11: [REGLA PROPIA] Foreign Key Cascade and Soft-Delete Referential Integrity
- **Condition**: `IF` `ALTER TABLE ... DROP CONSTRAINT` or `DELETE` is executed on a table with foreign key relations without specifying cascade strategy `OR` soft-delete pattern (`is_deleted` / `deleted_at`) is mixed with hard `DELETE`.
- **Action**: `THEN` flag as `HIGH` severity violation.
- **Justification**: Prevents orphaned records in child tables and accidental destruction of audited soft-deleted entity history.

### R12: [REGLA PROPIA] Implicit Data Type Coercion in Predicates
- **Condition**: `IF` join or filter predicate compares columns/values of mismatched data types (e.g., `VARCHAR_COL = 12345` or `INT_COL = '123'`).
- **Action**: `THEN` flag as `HIGH` severity violation.
- **Justification**: Implicit type conversion forces the database engine to cast every row dynamically during execution, disabling index lookups and causing high CPU utilization.

## Rule Conflict Resolution
When a single query violates multiple rules simultaneously, reporting priority and severity assignment follow a strict hierarchical order:

1. **Priority 1: Security Violations (`R02`, `R04`)** — Dynamic SQL injections and cosmetic `WHERE` clauses on `DELETE`/`UPDATE` override all other findings.
2. **Priority 2: Data Integrity & Destructive DDL (`R03`, `R07`, `R11`)** — Unrecoverable data loss or logic failures (e.g. `= NULL`).
3. **Priority 3: Performance Anti-Patterns (`R01`, `R06`, `R09`, `R10`, `R12`)** — Query latency, missing indexes, non-SARGable filters, and cosmetic limits.
4. **Priority 4: Conventions & Standards (`R05`, `R08`)** — Identifier naming and minor data type design preferences.

*Rule: The query's overall status takes the maximum severity of any individual finding triggered.*

## Severity Levels

| Severity Level | Definition & Decision Criteria | Action Required |
| :--- | :--- | :--- |
| **CRITICAL** | High probability of data loss, database compromise, or severe outage (e.g., `DELETE` without valid `WHERE`, SQL injection, destructive DDL, cosmetic `LIMIT >= 1000000000`). | Block deployment immediately. Mandatory refactoring. |
| **HIGH** | Performance degradation, severe memory bloat, or table scans on large tables (e.g., `SELECT *`, missing `LIMIT`, non-SARGable filters, missing FK indexes). | Requires remediation before merging to production. |
| **MEDIUM** | Logical bugs or sub-optimal data patterns (e.g., `= NULL`, implicit type casting, sub-optimal data types). | Recommended fix during current sprint. |
| **LOW** | Code formatting, naming convention non-compliance, missing aliases. | Minor warning, fix at developer discretion. |
| **INFO** | Ambiguity due to missing schema/index/volume context. Requires user verification. | Prompt user for context; do not block pipeline. |

## Expected Output
All reviews MUST output a Markdown report formatted as follows:

```markdown
# SQL Code Review Report

## Summary
- **Overall Result**: [PASSED | ACTION REQUIRED | INSUFFICIENT CONTEXT]
- **Highest Severity**: [CRITICAL | HIGH | MEDIUM | LOW | INFO]
- **Total Findings**: [Count]

## Findings Detail

| Line | Rule Violated | Severity | Technical Explanation | Recommended Remediation |
| :--- | :--- | :--- | :--- | :--- |
| Line N | R0X: Rule Name | SEVERITY | Technical description of the risk. | Specific SQL code fix. |

## Context Requests / UNKNOWN Declarations
- [List any missing schema, index, or volume data required to complete analysis]
```

## Validation
Before returning a review response, the skill executes an internal self-validation checklist:
- [ ] Were all 12 rules (`R01`-`R12`) evaluated against every statement?
- [ ] Were cosmetic evasion patterns (`WHERE 1=1`, `LIMIT 1000000000`, `LIKE '%'`) actively tested?
- [ ] Is every finding justified with technical risk explanation?
- [ ] Are missing contextual elements properly marked as `INFO`/`UNKNOWN` instead of hallucinated?
- [ ] Does output strictly match the template in Section 8?

## Failure Handling
1. **Invalid SQL Syntax**: If input cannot be parsed, return: `[ERROR] SQL Syntax Invalid on Line X: Unable to parse query. Please verify SQL syntax.`
2. **Unsupported Engine Dialect**: Return `[WARNING] Engine Dialect Unknown: Evaluated against ANSI SQL / standard relational rules.`
3. **Empty Input**: Return `[ERROR] Empty Input: No SQL statements provided for evaluation.`
4. **Missing Context (Schema/Indexes/Data Volume)**: Do **NOT** invent assumptions. Declare findings dependent on schema as `Severity: INFO` with status `UNKNOWN` and prompt the user: `[INFO] Cannot determine index coverage for table TA_USERS column FCEMAIL. Please provide schema index definitions.`

## Deterministic vs. Model-dependent

| Component / Rule | Classification | Execution Mechanism |
| :--- | :--- | :--- |
| **R01 (`SELECT *`)** | Deterministic | AST Projection / Regex pattern matching for wildcard `*`. |
| **R02 (`UPDATE/DELETE` safe `WHERE`)** | Hybrid (Deterministic + Model-dependent) | Pattern matching for missing `WHERE` + semantic analysis to detect cosmetic clauses (`1=1`, `LIKE '%'`). |
| **R03 (Destructive DDL)** | Deterministic | Keyword matching (`DROP`, `TRUNCATE`, `ALTER ... DROP`). |
| **R04 (SQL Injection)** | Hybrid | Detection of string concatenation operators + model semantic tracking of external variable flow. |
| **R05 (Naming Conventions)** | Deterministic | Identifier prefix matching (`TA_`, `FC`, `FN`, `FD`) against regex patterns. |
| **R06 (`LIMIT` enforcement)** | Hybrid | AST check for `LIMIT` presence + numerical evaluation for cosmetic limit bounds (>= 1,000,000). |
| **R07 (`NULL` comparisons)** | Deterministic | Regex/AST matching for `= NULL` or `!= NULL`. |
| **R08 (Data Types)** | Deterministic | Schema type definition matching (`VARCHAR` on PKs, text timestamps). |
| **R09 (Missing Indexes)** | Model-dependent | Cross-referencing query predicates with schema index definitions provided in prompt context. |
| **R10 (Performance Anti-Patterns)**| Model-dependent | Identifying scalar functions wrapping indexed columns & detecting correlated outer-query aliases. |
| **R11 (Soft-Delete Integrity)** | Model-dependent | Inferring schema deletion strategy (`is_deleted`) vs hard `DELETE` usage. |
| **R12 (Implicit Type Coercion)** | Deterministic | Predicate left-side vs right-side data type compatibility verification. |
