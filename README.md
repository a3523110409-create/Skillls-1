# SQL Reviewer Skill (`sql-reviewer-skill`)

A production-grade, deterministic AI skill for static analysis, security auditing, performance optimization, and conventions enforcement on SQL queries.

Designed for seamless integration into code review pipelines, LLM agent toolsets, and automated CI/CD workflows.

---

## 📌 Repository Structure

```
sql-reviewer-skill/
|-- SKILL.md                  # Main Skill Definition & Deterministic Execution Rules
|-- README.md                 # Project Overview & Usage Documentation
|-- rules/                    # Detailed Rule Definitions & Code Examples
|   |-- security.md           # Security & SQL Injection Mitigation Rules (SEC-R02, R04, R11)
|   |-- performance.md        # Latency, Indexing & Memory Optimization Rules (PERF-R01, R06, R09, R10, R12)
|   `-- conventions.md        # Naming Standards & 3VL Logic Handling Rules (CONV-R05, R07, R08)
|-- examples/                 # SQL Script Reference Files
|   |-- valid.sql             # Compliant SQL queries (0 false positives)
|   |-- invalid.sql           # Explicitly flawed queries violating R01-R12
|   `-- edge-cases.sql        # Semantic evasion & edge-case queries
`-- tests/                    # Evaluation & Verification Test Cases
    |-- test-01.md            # Test 01: Happy Path Evaluation
    |-- test-02.md            # Test 02: Evident Errors Evaluation
    |-- test-03.md            # Test 03: Edge Case / Non-SARGable Evaluation
    |-- test-04.md            # Test 04: Insufficient Information / UNKNOWN Context Evaluation
    `-- test-05.md            # Test 05: Red Team / Adversarial Evasion Evaluation
```

---

## 🚀 How to Use the Skill

### 1. In AI Agent Environments (Google Antigravity, Claude, ChatGPT, Cursor)
Copy the [`SKILL.md`](SKILL.md) file into your project's `.gemini/skills/sql-reviewer/SKILL.md` or `.cursor/rules/` directory.

### 2. Manual Execution Prompt
When prompting an AI assistant loaded with this skill:
```text
Review the following SQL statement using the sql-reviewer skill rules:

[INSERT YOUR SQL QUERY HERE]
```

### 3. CI/CD Pre-commit Hook Integration
Invoke the deterministic procedure defined in `SKILL.md` to evaluate SQL files against rules `R01` to `R12` prior to merging pull requests.

---

## 🛡️ Custom Team Rules Summary (`[REGLA PROPIA]`)

In addition to the 10 mandatory SQL review points, this repository includes **2 custom enterprise rules**:

1. **R11: Foreign Key Cascade and Soft-Delete Referential Integrity (`[REGLA PROPIA]`)**
   - **Trigger**: `IF` a query attempts a hard `DELETE` on a table with a soft-delete schema column (`is_deleted`, `fd_deleted_at`) `OR` executes un-cascaded foreign key constraint drops.
   - **Severity**: `HIGH` / `CRITICAL`
   - **Justification**: Prevents orphaned records in child tables and protects soft-deleted audit records from permanent deletion.

2. **R12: Implicit Data Type Coercion in Predicates (`[REGLA PROPIA]`)**
   - **Trigger**: `IF` a join predicate or `WHERE` clause compares mismatched data types (e.g. `VARCHAR_COL = 12345` or `INT_COL = '123'`).
   - **Severity**: `HIGH`
   - **Justification**: Dynamic type casting row-by-row neutralizes database indexes and consumes excessive CPU cycles.

---

## 🧪 Testing & Red Team Results Summary

All **5 verification test suites** passed with a **100% success rate**:

| Test Suite | Test Type | Status | Summary / Key Findings |
| :--- | :--- | :--- | :--- |
| **Test 01** | Happy Path | `PASSED` | Verified that clean queries generate zero false positives. |
| **Test 02** | Evident Errors | `PASSED` | Correctly flagged `DELETE` without `WHERE`, `SELECT *`, and `= NULL`. |
| **Test 03** | Edge Case | `PASSED` | Detected non-SARGable `LOWER()` function wrapper on indexed filter column. |
| **Test 04** | Insufficient Info | `PASSED` | Flagged missing schema context as `INFO / UNKNOWN` without inventing assumptions. |
| **Test 05** | Red Team / Adversarial | `PASSED` | Successfully blocked 5 evasion attempts (`1=1`, `LIMIT 1000000000`, `LIKE '%'`, tautological `OR`, and 5M limit). |

### Key Improvements Made Following Red Team Attack:
- Enhanced `R02` from literal `1=1` string matching to **semantic tautology evaluation** (`IS NOT NULL OR IS NULL`, `'x'='x'`).
- Enhanced `R06` to classify limits $\ge 1,000,000$ as **cosmetic memory evasion hazards**.
- Strengthened `Failure Handling` to ensure missing schema context triggers `INFO / UNKNOWN` status instead of hallucinating index status.
