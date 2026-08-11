-- =============================================================================
-- EXAMPLES: EDGE-CASE AND ADVERSARIAL SQL STATEMENTS
-- These statements superficially appear to satisfy syntax rules (e.g. they contain
-- WHERE clauses or LIMIT parameters), but employ evasion techniques or semantic
-- flaws that degrade performance or compromise data security.
-- =============================================================================

-- Edge Case 1: Cosmetic WHERE clause evasion (Evaluates to TRUE for all rows)
-- Superficially contains a WHERE clause, but bypasses bounded modification.
DELETE FROM TA_USERS WHERE 1 = 1;

-- Edge Case 2: Cosmetic LIMIT clause evasion (Astronomical limit parameter)
-- Superficially includes LIMIT, but 1 Billion limit provides zero OOM memory protection.
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS LIMIT 1000000000;

-- Edge Case 3: Cosmetic Wildcard WHERE clause evasion
-- Superficially includes WHERE clause with LIKE, but '%' matches 100% of non-null records.
UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';

-- Edge Case 4: Non-SARGable case-insensitive string search
-- Superficially valid query, but LOWER() function invalidates B-Tree index on FCEMAIL.
SELECT FNUSER_ID, FCNAME FROM TA_USERS WHERE LOWER(FCEMAIL) = 'admin@company.com' LIMIT 10;

-- Edge Case 5: Correlated N+1 Subquery in SELECT projection
-- Includes LIMIT 50, but subquery re-evaluates per row creating O(N) execution overhead.
SELECT u.FNUSER_ID, u.FCUSER_NAME, 
       (SELECT COUNT(*) FROM TA_ORDERS o WHERE o.FNUSER_ID = u.FNUSER_ID) AS total_orders
FROM TA_USERS u
LIMIT 50;
