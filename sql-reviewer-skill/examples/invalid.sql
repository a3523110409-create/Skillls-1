-- =============================================================================
-- EXAMPLES: INVALID SQL STATEMENTS
-- Each query below deliberately violates one or more rules from R01-R12.
-- =============================================================================

-- Statement 1: Violates R01 (SELECT *) and R06 (Missing LIMIT)
SELECT * FROM TA_USERS;

-- Statement 2: Violates R02 (DELETE without WHERE clause) [CRITICAL]
DELETE FROM TA_USERS;

-- Statement 3: Violates R03 (Destructive DDL TRUNCATE) [CRITICAL]
TRUNCATE TABLE TA_TRANSACTIONS;

-- Statement 4: Violates R04 (SQL Injection via string concatenation) [CRITICAL]
SELECT FCEMAIL, FCROLE FROM TA_USERS WHERE FCNAME = '' + input_name + '';

-- Statement 5: Violates R05 (Naming conventions: camelCase, reserved word 'user', no TA_ prefix)
CREATE TABLE users (
    userId INT,
    user VARCHAR(50)
);

-- Statement 6: Violates R07 (Incorrect NULL comparison using =)
SELECT FNUSER_ID, FCEMAIL FROM TA_USERS WHERE FDDELETED_AT = NULL;

-- Statement 7: Violates R08 (Poor data type choice: int stored as VARCHAR, date stored as VARCHAR)
CREATE TABLE TA_LOGS (
    FCLOG_ID VARCHAR(50) PRIMARY KEY,
    FCLOG_DATE VARCHAR(50)
);

-- Statement 8: Violates R10 (Non-SARGable scalar function wrapping indexed date column)
SELECT FNORDER_ID, FNTOTAL_AMOUNT FROM TA_ORDERS WHERE YEAR(FDORDER_DATE) = 2026;

-- Statement 9: Violates R11 [REGLA PROPIA] (Hard DELETE on table containing soft-delete column)
DELETE FROM TA_USERS WHERE FNUSER_ID = 505;

-- Statement 10: Violates R12 [REGLA PROPIA] (Implicit type coercion: VARCHAR column compared to Integer)
SELECT FNACCOUNT_ID FROM TA_ACCOUNTS WHERE FCACCOUNT_NUMBER = 998877;
